using System.Numerics;
using System.Net.Http.Json;
namespace FilmContest.Web.Services;
public sealed class AIService(Db db,Assets assets,IHttpClientFactory clients,IConfiguration config) {
 public async Task Analyze(int id) {
  var rows=await db.Query("SELECT SubmissionId,AssetKey,Sha256,PHash FROM dbo.Submissions WHERE SubmissionId=@id",("@id",id));if(rows.Rows.Count==0)return;
  var row=rows.Rows[0];var matches=await db.Query("SELECT TOP(2000) SubmissionId,Sha256,PHash FROM dbo.Submissions WHERE SubmissionId<>@id ORDER BY SubmissionId DESC",("@id",id));
  int? match=null;var distance=65;
  foreach(System.Data.DataRow m in matches.Rows){var d=m["Sha256"].ToString()==row["Sha256"].ToString()?0:BitOperations.PopCount(Convert.ToUInt64(m["PHash"].ToString(),16)^Convert.ToUInt64(row["PHash"].ToString(),16));if(d<distance){distance=d;match=(int)m["SubmissionId"];}}
  await db.Exec("EXEC dbo.usp_SaveAICheck @id,@kind,@status,@score,@detail,@version",("@id",id),("@kind","Similarity"),("@status",distance<=6?"Flagged":"Clear"),("@score",distance<=6?(64-distance)/64m:null),("@detail",distance<=6?$"Similar submission #{match}; dHash distance {distance}. Review manually.":"No close match in latest 2000 submissions; not proof of originality."),("@version","dHash-64-v1"));
  var endpoint=config["AI:Endpoint"];
  if(string.IsNullOrWhiteSpace(endpoint)) {
   foreach(var kind in new[]{"GeneratedImage","Tags"})await db.Exec("EXEC dbo.usp_SaveAICheck @id,@kind,'Unavailable',NULL,@detail,'none'",("@id",id),("@kind",kind),("@detail","External AI provider not configured; no detection result."));return;
  }
  try {
   if(!Uri.TryCreate(endpoint,UriKind.Absolute,out var uri)||uri.Scheme!="https")throw new InvalidOperationException("AI endpoint must use HTTPS");
   using var request=new HttpRequestMessage(HttpMethod.Post,uri);request.Headers.Add("X-Api-Key",config["AI:ApiKey"]);
   using var stream=await assets.Open(row["AssetKey"].ToString()!);using var memory=new MemoryStream();await stream.CopyToAsync(memory);
   request.Content=JsonContent.Create(new{imageBase64=Convert.ToBase64String(memory.ToArray()),mimeType="image/jpeg"});
   using var response=await clients.CreateClient("ai").SendAsync(request);response.EnsureSuccessStatusCode();
   var result=await response.Content.ReadFromJsonAsync<AIResponse>()??throw new InvalidOperationException("Empty AI response");
   if(result.AiProbability is <0 or >1||result.Tags==null||result.Tags.Length>30)throw new InvalidOperationException("Invalid AI response");
   await db.Exec("EXEC dbo.usp_SaveAICheck @id,'GeneratedImage',@status,@score,@detail,@version",("@id",id),("@status",result.AiProbability>=0.7m?"Flagged":"Clear"),("@score",result.AiProbability),("@detail","Provider estimate, not proof. Human review required."),("@version",config["AI:ModelVersion"]));
   await db.Exec("EXEC dbo.usp_SaveAICheck @id,'Tags','Clear',NULL,@detail,@version",("@id",id),("@detail",string.Join(", ",result.Tags).Substring(0,Math.Min(1900,string.Join(", ",result.Tags).Length))),("@version",config["AI:ModelVersion"]));
  } catch(Exception ex) when(ex is HttpRequestException or TaskCanceledException or InvalidOperationException or System.Text.Json.JsonException) {
   foreach(var kind in new[]{"GeneratedImage","Tags"})await db.Exec("EXEC dbo.usp_SaveAICheck @id,@kind,'Unavailable',NULL,'Provider failed; retry from review page.',@version",("@id",id),("@kind",kind),("@version",config["AI:ModelVersion"]));
  }
 }
 public record AIResponse([property:System.Text.Json.Serialization.JsonRequired] decimal AiProbability,[property:System.Text.Json.Serialization.JsonRequired] string[] Tags);
}
