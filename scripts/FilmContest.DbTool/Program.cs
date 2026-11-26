using Microsoft.Data.SqlClient;
using System.Text.RegularExpressions;
var root=Path.GetFullPath(args.Length>1?args[1]:".");var mode=args.FirstOrDefault()??"test";
if(mode is not ("init" or "update" or "test"))throw new Exception("Use init, update or test");
var connection=Environment.GetEnvironmentVariable("FILM_DB_ADMIN")??throw new Exception("Set FILM_DB_ADMIN to an administrative SQL connection string.");
await using var c=new SqlConnection(connection);await c.OpenAsync();
async Task RunFile(string path){Console.WriteLine("Running "+Path.GetFileName(path));foreach(var batch in Regex.Split(File.ReadAllText(path),@"^\s*GO\s*$",RegexOptions.Multiline|RegexOptions.IgnoreCase)){if(string.IsNullOrWhiteSpace(batch))continue;await using var cmd=new SqlCommand(batch,c){CommandTimeout=120};await cmd.ExecuteNonQueryAsync();}}
if(mode=="init"){
 var password=Environment.GetEnvironmentVariable("FILM_APP_PASSWORD")??throw new Exception("Set FILM_APP_PASSWORD (unique strong app SQL password)");if(password.Length<16||password.Length>128)throw new Exception("App SQL password must contain 16–128 characters");
 await using(var check=new SqlCommand("SELECT DB_ID(N'FilmContest')",c)){if(await check.ExecuteScalarAsync() is not DBNull)throw new Exception("FilmContest already exists. Use update to apply fixes; init requires a new database and will not overwrite existing data.");}
 foreach(var name in new[]{"01_schema.sql","02_procedures.sql","03_management.sql"})await RunFile(Path.Combine(root,"database",name));
 await using(var cmd=new SqlCommand("USE master; IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name='filmapp') BEGIN DECLARE @s nvarchar(max)=N'CREATE LOGIN filmapp WITH PASSWORD='+QUOTENAME(@p,'''')+N',CHECK_POLICY=ON';EXEC(@s); END;",c)){cmd.Parameters.AddWithValue("@p",password);await cmd.ExecuteNonQueryAsync();}
 await RunFile(Path.Combine(root,"database","04_security.sql"));await RunFile(Path.Combine(root,"database","05_demo.sql"));
 Console.WriteLine("Database initialized. If filmapp login already existed, its password was preserved; use that password for the website.");
}else if(mode=="update"){
 foreach(var name in new[]{"02_procedures.sql","03_management.sql","07_integrity_update.sql"})await RunFile(Path.Combine(root,"database",name));
 Console.WriteLine("Procedures and integrity constraint updated. Existing accounts and submissions preserved.");
}else {
 foreach(var name in new[]{"01_workflow.sql","02_regressions.sql"})await RunFile(Path.Combine(root,"tests",name));
 Console.WriteLine("PASS SQL integration workflow and regression tests");
}
