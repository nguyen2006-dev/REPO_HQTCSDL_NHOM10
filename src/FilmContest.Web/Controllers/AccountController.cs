using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.RateLimiting;
using FilmContest.Web.Services;
using FilmContest.Web.Models;
namespace FilmContest.Web.Controllers;
public sealed class AccountController(Db db,PasswordHasher<string> hasher,Tokens tokens):BaseController(db) {
 [HttpGet]public IActionResult Login()=>View(new LoginForm());
 [HttpPost,EnableRateLimiting("login")]public async Task<IActionResult> Login(LoginForm form){
  if(!ModelState.IsValid)return View(form);
  var rows=await DB.Query("SELECT * FROM dbo.Users WHERE Email=@email AND Active=1",("@email",form.Email.Trim().ToLowerInvariant()));
  if(rows.Rows.Count!=1||hasher.VerifyHashedPassword(form.Email,rows.Rows[0]["PasswordHash"].ToString()!,form.Password)==PasswordVerificationResult.Failed){ModelState.AddModelError("","Email hoặc mật khẩu không đúng.");return View(form);}
  var u=rows.Rows[0];Response.Cookies.Append("film_token",tokens.Create((int)u["UserId"],u["Name"].ToString()!,u["Role"].ToString()!,(int)u["TokenVersion"]),new CookieOptions{HttpOnly=true,Secure=Request.IsHttps,SameSite=SameSiteMode.Strict,MaxAge=TimeSpan.FromHours(2)});return RedirectToAction("Index","Home");
 }
 [HttpGet]public IActionResult Register()=>View(new RegisterForm());
 [HttpPost,EnableRateLimiting("login")]public async Task<IActionResult> Register(RegisterForm form){
  if(form.Password.Length<12)ModelState.AddModelError("Password","Mật khẩu tối thiểu 12 ký tự.");
  if(!ModelState.IsValid)return View(form);
  var ok=await TryRun(async()=>{await DB.Exec("INSERT dbo.Users(Email,Name,PasswordHash)VALUES(@email,@name,@hash)",("@email",form.Email.Trim().ToLowerInvariant()),("@name",form.Name),("@hash",hasher.HashPassword(form.Email,form.Password)));});
  return ok?RedirectToAction("Login"):View(form);
 }
 [Authorize,HttpPost]public async Task<IActionResult> Logout(){await DB.Exec("UPDATE dbo.Users SET TokenVersion=TokenVersion+1 WHERE UserId=@id",("@id",Actor));Response.Cookies.Delete("film_token");return RedirectToAction("Index","Home");}
 [Authorize,HttpGet]public async Task<IActionResult> Profile()=>View(await DB.Query("SELECT Name,Email,Role FROM dbo.Users WHERE UserId=@id",("@id",Actor)));
 [Authorize,HttpPost]public async Task<IActionResult> Profile(string name){if(!string.IsNullOrWhiteSpace(name)&&name.Length<=120)await DB.Exec("UPDATE dbo.Users SET Name=@name WHERE UserId=@id",("@name",name.Trim()),("@id",Actor));return RedirectToAction("Profile");}
}
