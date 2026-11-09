using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using FilmContest.Web.Models;
using FilmContest.Web.Services;
namespace FilmContest.Web.Controllers;
[Authorize(Roles="Participant")]
public sealed class StudioController(Db db,Assets assets,AIService ai):BaseController(db){
 public async Task<IActionResult> Index()=>View(await DB.Query("SELECT s.*,c.Title AS ContestTitle FROM dbo.Submissions s JOIN dbo.Contests c ON c.ContestId=s.ContestId WHERE s.UserId=@id ORDER BY SubmissionId DESC",("@id",Actor)));
 public async Task<IActionResult> Rolls(){ViewBag.Stocks=await DB.Query("SELECT * FROM dbo.FilmStocks WHERE Active=1 ORDER BY Brand,Name");return View(await DB.Query("SELECT * FROM dbo.FilmRolls WHERE UserId=@id",("@id",Actor)));}
 [HttpPost]public async Task<IActionResult> AddRoll(RollForm f){if(ModelState.IsValid)await TryRun(async()=>{await DB.Exec("INSERT dbo.FilmRolls(UserId,Name,StockId,Stock,ISO,Camera,Lens,Format,Lab)SELECT @id,@name,StockId,LEFT(CONCAT(Brand,' ',Name),100),@iso,@camera,@lens,@format,@lab FROM dbo.FilmStocks WHERE StockId=@stock AND Active=1",("@id",Actor),("@name",f.Name),("@stock",f.StockId),("@iso",f.ISO),("@camera",f.Camera),("@lens",f.Lens),("@format",f.Format),("@lab",f.Lab));});else TempData["Error"]="Kiểm tra lại thông tin cuộn phim.";return RedirectToAction("Rolls");}
 private async Task Load(int contest){ViewBag.Categories=await DB.Query("SELECT * FROM dbo.Categories WHERE ContestId=@id",("@id",contest));ViewBag.Rolls=await DB.Query("SELECT * FROM dbo.FilmRolls WHERE UserId=@id",("@id",Actor));}
 [HttpGet]public async Task<IActionResult> Submit(int id){await Load(id);return View(new SubmissionForm{ContestId=id});}
 [HttpPost,RequestSizeLimit(12*1024*1024)]public async Task<IActionResult> Submit(SubmissionForm f){
  if(!ModelState.IsValid){await Load(f.ContestId);return View(f);}
  StoredPhoto? saved=null;int submission=0;
  var ok=await TryRun(async()=>{saved=await assets.Save(f.Photo);submission=Convert.ToInt32(await DB.Scalar("EXEC dbo.usp_Submit @Actor,@Contest,@Category,@Roll,@Frame,@Title,@Location,@Scan,@Negative,@Key,@Sha,@PHash,@Width,@Height",("@Actor",Actor),("@Contest",f.ContestId),("@Category",f.CategoryId),("@Roll",f.RollId),("@Frame",f.FrameNumber),("@Title",f.Title),("@Location",f.Location),("@Scan",f.ScanSpecs),("@Negative",f.NegativeReference),("@Key",saved.Key),("@Sha",saved.Sha256),("@PHash",saved.PerceptualHash),("@Width",saved.Width),("@Height",saved.Height)));});
  if(!ok){if(saved!=null)await assets.Delete(saved.Key);await Load(f.ContestId);return View(f);}
  // Submission is durable before AI. Provider failure must never undo an accepted upload.
  try{await ai.Analyze(submission);}catch(Exception){TempData["Error"]="Đã lưu bài; phân tích AI chưa hoàn tất. Ban tổ chức có thể chạy lại.";}
  return RedirectToAction("Index");
 }
 public async Task<IActionResult> Feedback(int id){if(await DB.Scalar("SELECT SubmissionId FROM dbo.Submissions WHERE SubmissionId=@id AND UserId=@actor",("@id",id),("@actor",Actor))==null)return NotFound();ViewBag.Reviews=await DB.Query("SELECT Decision,Reason,ReviewedAt FROM dbo.SubmissionReviews WHERE SubmissionId=@id ORDER BY ReviewId DESC",("@id",id));return View(await DB.Query("SELECT r.Name AS RoundName,cr.Name AS Criterion,s.Score,s.Comment FROM dbo.Scores s JOIN dbo.JudgeAssignments a ON a.AssignmentId=s.AssignmentId JOIN dbo.JudgingRounds r ON r.RoundId=a.RoundId JOIN dbo.Criteria cr ON cr.CriterionId=s.CriterionId JOIN dbo.Contests c ON c.ContestId=r.ContestId WHERE a.SubmissionId=@id AND a.Finalized=1 AND c.Status='Published'",("@id",id)));}
}
