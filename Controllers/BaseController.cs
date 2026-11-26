using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using FilmContest.Web.Services;
namespace FilmContest.Web.Controllers;
public abstract class BaseController(Db db):Controller {
 protected readonly Db DB=db;
 protected int Actor=>User.UserId();
 protected async Task<bool> TryRun(Func<Task> work) {try{await work();TempData["Success"]="Đã lưu thành công.";return true;}catch(SqlException e)when(e.Number>=51000||e.Number is 2601 or 2627 or 547){TempData["Error"]=e.Number>=51000?e.Message:"Dữ liệu bị trùng hoặc không hợp lệ.";return false;}catch(InvalidOperationException e){TempData["Error"]=e.Message;return false;}}
 protected async Task<bool> Owns(int id)=>await DB.Scalar("SELECT ContestId FROM dbo.Contests WHERE ContestId=@id AND (OwnerId=@actor OR @admin=1)",("@id",id),("@actor",Actor),("@admin",User.IsInRole("Admin")))!=null;
}
