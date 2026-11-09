using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using FilmContest.Web.Services;
namespace FilmContest.Web.Controllers;
[Authorize(Roles="Judge")]
public sealed class JudgeController(Db db):BaseController(db){
 public async Task<IActionResult> Index()=>View(await DB.Query("SELECT a.*,s.Title,c.Title AS ContestTitle,r.Name AS RoundName,r.State FROM dbo.JudgeAssignments a JOIN dbo.Submissions s ON s.SubmissionId=a.SubmissionId JOIN dbo.JudgingRounds r ON r.RoundId=a.RoundId JOIN dbo.Contests c ON c.ContestId=r.ContestId WHERE a.JudgeId=@id ORDER BY a.AssignmentId DESC",("@id",Actor)));
 public async Task<IActionResult> Entry(int id){var rows=await DB.Query("SELECT a.*,s.Title,r.State,fr.FrameNumber,fr.Location,fr.ScanSpecs,roll.Stock,roll.ISO,roll.Camera,roll.Lens,roll.Format FROM dbo.JudgeAssignments a JOIN dbo.Submissions s ON s.SubmissionId=a.SubmissionId JOIN dbo.JudgingRounds r ON r.RoundId=a.RoundId JOIN dbo.Frames fr ON fr.FrameId=s.FrameId JOIN dbo.FilmRolls roll ON roll.RollId=fr.RollId WHERE a.AssignmentId=@id AND a.JudgeId=@actor",("@id",id),("@actor",Actor));if(rows.Rows.Count==0)return NotFound();ViewBag.Criteria=await DB.Query("SELECT cr.*,sc.Score,sc.Comment FROM dbo.Criteria cr JOIN dbo.JudgingRounds r ON r.ContestId=cr.ContestId JOIN dbo.JudgeAssignments a ON a.RoundId=r.RoundId LEFT JOIN dbo.Scores sc ON sc.AssignmentId=a.AssignmentId AND sc.CriterionId=cr.CriterionId WHERE a.AssignmentId=@id",("@id",id));return View(rows);}
 [HttpPost]public async Task<IActionResult> Score(int assignment,int criterion,decimal score,string comment){await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_Score @Actor,@Assignment,@Criterion,@Score,@Comment",("@Actor",Actor),("@Assignment",assignment),("@Criterion",criterion),("@Score",score),("@Comment",comment??""));});return RedirectToAction("Entry",new{id=assignment});}
 [HttpPost]public async Task<IActionResult> FinalizeScore(int id){await TryRun(async()=>{await DB.Exec("EXEC dbo.usp_FinalizeScore @Actor,@Assignment",("@Actor",Actor),("@Assignment",id));});return RedirectToAction("Entry",new{id});}
}
