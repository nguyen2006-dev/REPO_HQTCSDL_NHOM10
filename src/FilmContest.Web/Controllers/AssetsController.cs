using Microsoft.AspNetCore.Mvc;
using FilmContest.Web.Services;
namespace FilmContest.Web.Controllers;
public sealed class AssetsController(Db db,Assets assets):BaseController(db){
 [HttpGet]public async Task<IActionResult> Photo(int id){
  var rows=await DB.Query("SELECT s.AssetKey,s.UserId,c.OwnerId,c.Status,CASE WHEN EXISTS(SELECT 1 FROM dbo.SubmissionAwards sa WHERE sa.SubmissionId=s.SubmissionId)THEN 1 ELSE 0 END AS Awarded FROM dbo.Submissions s JOIN dbo.Contests c ON c.ContestId=s.ContestId WHERE s.SubmissionId=@id",("@id",id));if(rows.Rows.Count==0)return NotFound();var r=rows.Rows[0];
  bool allowed=r["Status"].ToString()=="Published"&&(int)r["Awarded"]==1;
  if(User.Identity?.IsAuthenticated==true)allowed|=User.IsInRole("Admin")||(int)r["UserId"]==Actor||(int)r["OwnerId"]==Actor||await DB.Scalar("SELECT TOP(1) AssignmentId FROM dbo.JudgeAssignments WHERE SubmissionId=@id AND JudgeId=@actor",("@id",id),("@actor",Actor))!=null;
  if(!allowed)return Forbid();Response.Headers.CacheControl="private, no-store";return File(await assets.Open(r["AssetKey"].ToString()!),"image/jpeg");
 }
}
