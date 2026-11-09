using Microsoft.AspNetCore.Mvc;
using FilmContest.Web.Services;
namespace FilmContest.Web.Controllers;
public sealed class HomeController(Db db):BaseController(db){
 public async Task<IActionResult> Index(){ViewBag.Banner=await DB.Scalar("SELECT SettingValue FROM dbo.PlatformSettings WHERE SettingKey='Banner'");return View(await DB.Query("SELECT TOP(6) * FROM dbo.Contests WHERE Status<>'Draft' ORDER BY ContestId DESC"));}
 public async Task<IActionResult> Archive()=>View(await DB.Query("SELECT * FROM dbo.v_Archive ORDER BY ContestId DESC"));
 public IActionResult Error(){Response.StatusCode=500;return View();}
}
