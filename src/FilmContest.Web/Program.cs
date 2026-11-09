using System.Text;
using System.Threading.RateLimiting;
using FilmContest.Web.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
var b=WebApplication.CreateBuilder(args);
var key=b.Configuration["Jwt:Key"];
if(string.IsNullOrWhiteSpace(key)||Encoding.UTF8.GetByteCount(key)<32)throw new InvalidOperationException("Configure Jwt__Key with at least 32 random bytes; see README.");
b.Services.AddControllersWithViews(o=>o.Filters.Add(new AutoValidateAntiforgeryTokenAttribute()));
b.Services.AddScoped<Db>();b.Services.AddScoped<Tokens>();b.Services.AddScoped<Assets>();b.Services.AddScoped<AIService>();
b.Services.AddSingleton<PasswordHasher<string>>();b.Services.AddHttpClient("ai",c=>c.Timeout=TimeSpan.FromSeconds(45));
b.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(o=>{
 o.TokenValidationParameters=new(){ValidateIssuer=true,ValidateAudience=true,ValidateLifetime=true,ValidateIssuerSigningKey=true,ValidIssuer=b.Configuration["Jwt:Issuer"],ValidAudience=b.Configuration["Jwt:Audience"],IssuerSigningKey=new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)),ClockSkew=TimeSpan.FromSeconds(30)};
 o.Events=new JwtBearerEvents {
 OnMessageReceived=c=>{if(c.Request.Cookies.TryGetValue("film_token",out var token))c.Token=token;return Task.CompletedTask;},
 OnTokenValidated=async c=>{var db=c.HttpContext.RequestServices.GetRequiredService<Db>();var t=await db.Query("SELECT Role,TokenVersion FROM dbo.Users WHERE UserId=@id AND Active=1",("@id",c.Principal!.UserId()));if(t.Rows.Count!=1||t.Rows[0]["Role"].ToString()!=c.Principal!.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value||t.Rows[0]["TokenVersion"].ToString()!=c.Principal!.FindFirst("ver")?.Value)c.Fail("Session revoked");},
 OnChallenge=c=>{if(!c.Request.Path.StartsWithSegments("/api")){c.HandleResponse();c.Response.Redirect("/Account/Login");}return Task.CompletedTask;},
 OnForbidden=c=>{c.Response.StatusCode=403;return Task.CompletedTask;}
 };
});
b.Services.AddAuthorization();b.Services.AddRateLimiter(o=>{o.RejectionStatusCode=429;o.AddPolicy("login",c=>RateLimitPartition.GetFixedWindowLimiter(c.Connection.RemoteIpAddress?.ToString()??"unknown",_=>new FixedWindowRateLimiterOptions{PermitLimit=10,Window=TimeSpan.FromMinutes(1),QueueLimit=0}));});
b.WebHost.ConfigureKestrel(o=>o.Limits.MaxRequestBodySize=12*1024*1024);
// Only trust a specifically configured reverse proxy, never arbitrary forwarded headers.
var proxy=b.Configuration["Hosting:KnownProxy"];
if(!string.IsNullOrWhiteSpace(proxy))b.Services.Configure<Microsoft.AspNetCore.Builder.ForwardedHeadersOptions>(o=>{o.ForwardedHeaders=Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedFor|Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedProto;o.KnownProxies.Add(System.Net.IPAddress.Parse(proxy));});
var app=b.Build();
if(!string.IsNullOrWhiteSpace(proxy))app.UseForwardedHeaders();
if(!app.Environment.IsDevelopment()){app.UseExceptionHandler("/Home/Error");app.UseHsts();app.UseHttpsRedirection();}
app.Use(async(c,next)=>{c.Response.Headers["X-Content-Type-Options"]="nosniff";c.Response.Headers["X-Frame-Options"]="DENY";c.Response.Headers["Referrer-Policy"]="same-origin";c.Response.Headers["Content-Security-Policy"]="default-src 'self'; img-src 'self' data:; style-src 'self'; form-action 'self'; frame-ancestors 'none'";await next();});
app.UseStaticFiles();app.UseRouting();app.UseRateLimiter();app.UseAuthentication();app.UseAuthorization();
app.MapControllerRoute("default","{controller=Home}/{action=Index}/{id?}");
// First admin is explicitly configured, never a shared default password.
using(var scope=app.Services.CreateScope()){
 var email=b.Configuration["Bootstrap:AdminEmail"];var pw=b.Configuration["Bootstrap:AdminPassword"];
 if(!string.IsNullOrWhiteSpace(email)&&!string.IsNullOrWhiteSpace(pw)){
  if(pw.Length<12)throw new InvalidOperationException("Bootstrap password must contain at least 12 characters.");
  var db=scope.ServiceProvider.GetRequiredService<Db>();var hash=scope.ServiceProvider.GetRequiredService<PasswordHasher<string>>().HashPassword(email,pw);
  await db.Exec("EXEC dbo.usp_BootstrapAdmin @Email,@Hash",("@Email",email.Trim().ToLowerInvariant()),("@Hash",hash));
 }
}
app.Run();
