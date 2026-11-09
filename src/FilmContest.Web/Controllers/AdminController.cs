using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using FilmContest.Web.Services;
namespace FilmContest.Web.Controllers;
[Authorize(Roles="Admin")]
public sealed class AdminController(Db db):BaseController(db){
 public async Task<IActionResult> Index(){ViewBag.Settings=await DB.Query("SELECT * FROM dbo.PlatformSettings");ViewBag.Stocks=await DB.Query("SELECT * FROM dbo.FilmStocks ORDER BY Brand,Name");ViewBag.Logs=await DB.Query("SELECT TOP(100) * FROM dbo.AuditLog ORDER BY AuditId DESC");return View(await DB.Query("SELECT UserId,Name,Email,Role,Active,CreatedAt FROM dbo.Users ORDER BY UserId"));}
 [HttpPost]public async Task<IActionResult> Setting(string key,string value){await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_SetSetting @Actor,@Key,@Value",("@Actor",Actor),("@Key",key),("@Value",value??""));});return RedirectToAction("Index");}
 [HttpPost]public async Task<IActionResult> Stock(string brand,string name,int iso){if(string.IsNullOrWhiteSpace(brand)||string.IsNullOrWhiteSpace(name)||brand.Length>80||name.Length>100)return BadRequest();await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_AddStock @Actor,@Brand,@Name,@ISO",("@Actor",Actor),("@Brand",brand),("@Name",name),("@ISO",iso));});return RedirectToAction("Index");}
 [HttpPost]public async Task<IActionResult> UserRole(int id,string role,bool active){await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_ChangeUser @Actor,@Target,@Role,@Active",("@Actor",Actor),("@Target",id),("@Role",role),("@Active",active));});return RedirectToAction("Index");}
}
