using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using FilmContest.Web.Models;
using FilmContest.Web.Services;
namespace FilmContest.Web.Controllers;
[Authorize(Roles="Organizer,Admin")]
public sealed class OrganizerController(Db db,AIService ai):BaseController(db){
 public async Task<IActionResult> Index()=>View(await DB.Query("SELECT * FROM dbo.Contests WHERE OwnerId=@id OR @admin=1 ORDER BY ContestId DESC",("@id",Actor),("@admin",User.IsInRole("Admin"))));
 [HttpGet]public IActionResult Create()=>View(new ContestForm());
 [HttpPost]public async Task<IActionResult> Create(ContestForm f){if(!ModelState.IsValid)return View(f);int id=0;var ok=await TryRun(async()=>{id=Convert.ToInt32(await DB.Scalar("EXEC dbo.usp_CreateContest @Actor,@Title,@Rules,@Opens,@Closes,@Max,@Category",("@Actor",Actor),("@Title",f.Title),("@Rules",f.Rules),("@Opens",f.Opens),("@Closes",f.Closes),("@Max",f.MaxEntries),("@Category",f.Category)));});return ok?RedirectToAction("Manage",new{id}):View(f);}
 public async Task<IActionResult> Manage(int id){if(!await Owns(id))return Forbid();
  ViewBag.Categories=await DB.Query("SELECT * FROM dbo.Categories WHERE ContestId=@id",("@id",id));
  ViewBag.Criteria=await DB.Query("SELECT * FROM dbo.Criteria WHERE ContestId=@id",("@id",id));
  ViewBag.Rounds=await DB.Query("SELECT * FROM dbo.JudgingRounds WHERE ContestId=@id ORDER BY RoundNumber",("@id",id));
  ViewBag.Judges=await DB.Query("SELECT UserId,Name,Email FROM dbo.Users WHERE Role='Judge' AND Active=1");
  ViewBag.Submissions=await DB.Query("SELECT s.*,u.Name,cat.Name AS CategoryName FROM dbo.Submissions s JOIN dbo.Users u ON u.UserId=s.UserId JOIN dbo.Categories cat ON cat.CategoryId=s.CategoryId WHERE s.ContestId=@id ORDER BY SubmissionId",("@id",id));
  ViewBag.Assignments=await DB.Query("SELECT a.*,u.Name AS JudgeName,r.Name AS RoundName FROM dbo.JudgeAssignments a JOIN dbo.JudgingRounds r ON r.RoundId=a.RoundId JOIN dbo.Users u ON u.UserId=a.JudgeId WHERE r.ContestId=@id",("@id",id));
  ViewBag.Awards=await DB.Query("SELECT * FROM dbo.Awards WHERE ContestId=@id",("@id",id));
  ViewBag.Winners=await DB.Query("SELECT a.Name,s.Title,s.SubmissionId FROM dbo.SubmissionAwards sa JOIN dbo.Awards a ON a.AwardId=sa.AwardId JOIN dbo.Submissions s ON s.SubmissionId=sa.SubmissionId WHERE a.ContestId=@id",("@id",id));
  ViewBag.Rankings=await DB.Query("SELECT * FROM dbo.v_Rankings WHERE ContestId=@id ORDER BY CategoryId,Position",("@id",id));
  return View(await DB.Query("SELECT * FROM dbo.Contests WHERE ContestId=@id",("@id",id)));
 }
 [HttpPost]public async Task<IActionResult> Configure(int id,string operation,string name,decimal weight=0){if(!await Owns(id))return Forbid();
  await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_Configure @Actor,@Contest,@Operation,@Name,@Weight",("@Actor",Actor),("@Contest",id),("@Operation",operation),("@Name",name??""),("@Weight",weight));});return RedirectToAction("Manage",new{id});}
 [HttpPost]public async Task<IActionResult> Schedule(int id,DateTime start,DateTime end){await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_Schedule @Actor,@Contest,@Start,@End",("@Actor",Actor),("@Contest",id),("@Start",start),("@End",end));});return RedirectToAction("Manage",new{id});}
 [HttpPost]public async Task<IActionResult> Open(int id){await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_OpenContest @Actor,@Contest",("@Actor",Actor),("@Contest",id));});return RedirectToAction("Manage",new{id});}
 [HttpPost]public async Task<IActionResult> Clone(int id){int copy=0;var ok=await TryRun(async()=>{copy=Convert.ToInt32(await DB.Scalar("EXEC dbo.usp_CloneContest @Actor,@Contest",("@Actor",Actor),("@Contest",id)));});return RedirectToAction("Manage",new{id=ok?copy:id});}
 [HttpPost]public async Task<IActionResult> Start(int id){await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_StartJudging @Actor,@Contest",("@Actor",Actor),("@Contest",id));});return RedirectToAction("Manage",new{id});}
 [HttpPost]public async Task<IActionResult> Assign(int id,int round,int submission,int judge){if(!await Owns(id))return Forbid();if(await DB.Scalar("SELECT RoundId FROM dbo.JudgingRounds WHERE RoundId=@r AND ContestId=@c",("@r",round),("@c",id))==null)return BadRequest();await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_Assign @Actor,@Round,@Submission,@Judge",("@Actor",Actor),("@Round",round),("@Submission",submission),("@Judge",judge));});return RedirectToAction("Manage",new{id});}
 [HttpPost]public async Task<IActionResult> RoundAction(int id,int round,string operation){if(!await Owns(id))return Forbid();await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_RoundAction @Actor,@Contest,@Round,@Operation",("@Actor",Actor),("@Contest",id),("@Round",round),("@Operation",operation));});return RedirectToAction("Manage",new{id});}
 public async Task<IActionResult> Review(int id){var c=await DB.Scalar("SELECT ContestId FROM dbo.Submissions WHERE SubmissionId=@id",("@id",id));if(c==null)return NotFound();if(!await Owns((int)c))return Forbid();
  ViewBag.Checks=await DB.Query("SELECT * FROM dbo.AICheckResults WHERE SubmissionId=@id",("@id",id));
  return View(await DB.Query("SELECT s.*,f.FrameNumber,f.Location,f.ScanSpecs,f.NegativeReference,r.Stock,r.ISO,r.Camera,r.Lens,r.Format,r.Lab,u.Name FROM dbo.Submissions s JOIN dbo.Frames f ON f.FrameId=s.FrameId JOIN dbo.FilmRolls r ON r.RollId=f.RollId JOIN dbo.Users u ON u.UserId=s.UserId WHERE s.SubmissionId=@id",("@id",id)));
 }
 [HttpPost]public async Task<IActionResult> Review(int id,string decision,string reason){await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_Review @Actor,@Submission,@Decision,@Reason",("@Actor",Actor),("@Submission",id),("@Decision",decision),("@Reason",reason??""));});return RedirectToAction("Review",new{id});}
 [HttpPost]public async Task<IActionResult> Analyze(int id){var contest=await DB.Scalar("SELECT ContestId FROM dbo.Submissions WHERE SubmissionId=@id",("@id",id));if(contest==null)return NotFound();if(!await Owns((int)contest))return Forbid();await TryRun(()=>ai.Analyze(id));return RedirectToAction("Review",new{id});}
 [HttpPost]public async Task<IActionResult> Award(int id,int award,int submission){await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_Award @Actor,@Contest,@Award,@Submission",("@Actor",Actor),("@Contest",id),("@Award",award),("@Submission",submission));});return RedirectToAction("Manage",new{id});}
 [HttpPost]public async Task<IActionResult> Publish(int id){await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_Publish @Actor,@Contest",("@Actor",Actor),("@Contest",id));});return RedirectToAction("Manage",new{id});}
 public async Task<IActionResult> Report(int id){if(!await Owns(id))return Forbid();ViewBag.Id=id;return View(await DB.Query("SELECT cat.Name AS Category,COUNT(s.SubmissionId) AS Entries,SUM(CASE WHEN s.Status='Approved' THEN 1 ELSE 0 END) AS Approved,SUM(CASE WHEN s.Status='Rejected' THEN 1 ELSE 0 END) AS Rejected,SUM(CASE WHEN s.Status='Pending' THEN 1 ELSE 0 END) AS Pending FROM dbo.Categories cat LEFT JOIN dbo.Submissions s ON s.CategoryId=cat.CategoryId WHERE cat.ContestId=@id GROUP BY cat.Name",("@id",id)));}
 public async Task<IActionResult> Export(int id){if(!await Owns(id))return Forbid();var t=await DB.Query("SELECT SubmissionId,Title,Photographer,TotalScore,Position FROM dbo.v_Rankings WHERE ContestId=@id ORDER BY CategoryId,Position",("@id",id));
  string Cell(object value){var s=value.ToString()??"";if(s.Length>0&&"=+-@\t\r".Contains(s[0]))s="'"+s;return "\""+s.Replace("\"","\"\"")+"\"";}
  var csv="\uFEFF"+string.Join(",",t.Columns.Cast<System.Data.DataColumn>().Select(c=>Cell(c.ColumnName)))+"\r\n"+string.Join("\r\n",t.Rows.Cast<System.Data.DataRow>().Select(r=>string.Join(",",r.ItemArray.Select(v=>Cell(v!)))));return File(System.Text.Encoding.UTF8.GetBytes(csv),"text/csv; charset=utf-8","rankings.csv");}
}
