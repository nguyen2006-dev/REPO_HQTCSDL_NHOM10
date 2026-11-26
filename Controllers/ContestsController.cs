using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using FilmContest.Web.Services;
namespace FilmContest.Web.Controllers;
public sealed class ContestsController(Db db):BaseController(db){
 public async Task<IActionResult> Index()=>View(await DB.Query("SELECT * FROM dbo.Contests WHERE Status<>'Draft' ORDER BY ContestId DESC"));
 public async Task<IActionResult> Detail(int id){
  var rows=await DB.Query("SELECT * FROM dbo.Contests WHERE ContestId=@id AND Status<>'Draft'",("@id",id));if(rows.Rows.Count==0)return NotFound();
  ViewBag.Categories=await DB.Query("SELECT * FROM dbo.Categories WHERE ContestId=@id",("@id",id));
  ViewBag.Criteria=await DB.Query("SELECT * FROM dbo.Criteria WHERE ContestId=@id",("@id",id));return View(rows);
 }
 [Authorize(Roles="Participant"),HttpPost]public async Task<IActionResult> Register(int id){await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_RegisterContest @Actor,@Contest",("@Actor",Actor),("@Contest",id));});return RedirectToAction("Detail",new{id});}
 public async Task<IActionResult> Results(int id){if(await DB.Scalar("SELECT ContestId FROM dbo.Contests WHERE ContestId=@id AND Status='Published'",("@id",id))==null)return NotFound();ViewBag.Id=id;return View(await DB.Query("SELECT * FROM dbo.v_Rankings WHERE ContestId=@id ORDER BY CategoryId,Position",("@id",id)));}
}
