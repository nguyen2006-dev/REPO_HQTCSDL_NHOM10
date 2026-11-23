using FilmContest.Web.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.FileProviders;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using System.IdentityModel.Tokens.Jwt;
using SkiaSharp;
var root=Path.GetFullPath(args.FirstOrDefault()??".");
var failed=0;var passed=0;
async Task Check(string name,Func<Task> work){try{await work();Console.WriteLine("PASS "+name);passed++;}catch(Exception ex){Console.WriteLine("FAIL "+name+": "+ex.Message);failed++;}}
void Assert(bool value,string message){if(!value)throw new Exception(message);}
await Check("All T-SQL scripts parse as SQL Server 2022",()=>{
 foreach(var path in Directory.GetFiles(Path.Combine(root,"database"),"*.sql").Concat(Directory.GetFiles(Path.Combine(root,"tests"),"*.sql"))){var parser=new TSql160Parser(true);parser.Parse(new StringReader(File.ReadAllText(path)),out var errors);Assert(errors.Count==0,Path.GetFileName(path)+": "+string.Join("; ",errors.Select(e=>$"line {e.Line}: {e.Message}")));}return Task.CompletedTask;});
await Check("Password hash accepts original and rejects wrong password",()=>{var h=new PasswordHasher<string>();var hash=h.HashPassword("u","a-long-password-123");Assert(hash!="a-long-password-123","Plain text hash");Assert(h.VerifyHashedPassword("u",hash,"a-long-password-123")!=PasswordVerificationResult.Failed,"Correct password rejected");Assert(h.VerifyHashedPassword("u",hash,"wrong")==PasswordVerificationResult.Failed,"Wrong password accepted");return Task.CompletedTask;});
var config=new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string,string?>{{"Jwt:Key","test-only-key-123456789012345678901234567890"},{"Jwt:Issuer","test"},{"Jwt:Audience","test"},{"Storage:Provider","Local"}}).Build();
await Check("JWT includes role and revocation version, expires in two hours",()=>{var token=new JwtSecurityTokenHandler().ReadJwtToken(new Tokens(config).Create(7,"Test","Judge",3));Assert(token.Claims.Any(c=>c.Type=="ver"&&c.Value=="3"),"Missing version");Assert(token.Claims.Any(c=>c.Value=="Judge"),"Missing role");Assert(token.ValidTo>DateTime.UtcNow.AddMinutes(119)&&token.ValidTo<DateTime.UtcNow.AddMinutes(121),"Expiry invalid");return Task.CompletedTask;});
var temp=Path.Combine(Path.GetTempPath(),"film-check-"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(temp);var assets=new Assets(config,new TestEnv{ContentRootPath=temp});
await Check("Upload rejects undersized photo",async()=>{using var image=new SKBitmap(20,20);using var encoded=SKImage.FromBitmap(image);using var data=encoded.Encode(SKEncodedImageFormat.Png,100);using var ms=new MemoryStream(data.ToArray());try{await assets.Save(new FormFile(ms,0,ms.Length,"Photo","tiny.png"));throw new Exception("Small photo accepted");}catch(InvalidOperationException){}});
await Check("Valid photo stored privately, hash stable, image can reopen",async()=>{using var image=new SKBitmap(800,600);using var encoded=SKImage.FromBitmap(image);using var data=encoded.Encode(SKEncodedImageFormat.Png,100);using var ms=new MemoryStream(data.ToArray());var saved=await assets.Save(new FormFile(ms,0,ms.Length,"Photo","test.png"));Assert(saved.Width==800&&saved.Height==600,"Wrong dimensions");Assert(saved.Sha256.Length==64&&saved.PerceptualHash.Length==16,"Invalid hashes");using(var stream=await assets.Open(saved.Key)){using var decoded=SKBitmap.Decode(stream);Assert(decoded.Width==800,"Cannot reopen");}await assets.Delete(saved.Key);});
await Check("Portrait photo accepted",async()=>{using var image=new SKBitmap(600,800);using var encoded=SKImage.FromBitmap(image);using var data=encoded.Encode(SKEncodedImageFormat.Png,100);using var ms=new MemoryStream(data.ToArray());var saved=await assets.Save(new FormFile(ms,0,ms.Length,"Photo","portrait.png"));Assert(saved.Width==600&&saved.Height==800,"Portrait dimensions changed");await assets.Delete(saved.Key);});
await Check("Asset path traversal rejected",async()=>{try{using var stream=await assets.Open("../../secret");throw new Exception("Path traversal accepted");}catch(InvalidOperationException){}});
Directory.Delete(temp,true);
Console.WriteLine($"{passed} passed, {failed} failed. SQL execution/E2E require separate SQL Server; see tests/README.md.");return failed==0?0:1;
public class TestEnv:IWebHostEnvironment {public string ApplicationName{get;set;}="Test";public string EnvironmentName{get;set;}="Development";public string ContentRootPath{get;set;}="";public IFileProvider ContentRootFileProvider{get;set;}=new NullFileProvider();public string WebRootPath{get;set;}="";public IFileProvider WebRootFileProvider{get;set;}=new NullFileProvider();}
