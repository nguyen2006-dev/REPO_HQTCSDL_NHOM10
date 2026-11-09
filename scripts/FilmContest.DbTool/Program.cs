using Microsoft.Data.SqlClient;
using System.Text.RegularExpressions;
var root=Path.GetFullPath(args.Length>1?args[1]:".");var mode=args.FirstOrDefault()??"test";
var connection=Environment.GetEnvironmentVariable("FILM_DB_ADMIN")??throw new Exception("Set FILM_DB_ADMIN to an administrative SQL connection string for a TEST database.");
await using var c=new SqlConnection(connection);await c.OpenAsync();
async Task RunFile(string path){Console.WriteLine("Running "+Path.GetFileName(path));foreach(var batch in Regex.Split(File.ReadAllText(path),@"^\s*GO\s*$",RegexOptions.Multiline|RegexOptions.IgnoreCase)){if(string.IsNullOrWhiteSpace(batch))continue;await using var cmd=new SqlCommand(batch,c){CommandTimeout=120};await cmd.ExecuteNonQueryAsync();}}
if(mode=="init"){
 var password=Environment.GetEnvironmentVariable("FILM_APP_PASSWORD")??throw new Exception("Set FILM_APP_PASSWORD (unique strong app SQL password)");if(password.Length<16)throw new Exception("App SQL password must be at least 16 characters");
 foreach(var name in new[]{"01_schema.sql","02_procedures.sql","03_management.sql"})await RunFile(Path.Combine(root,"database",name));
 await using(var cmd=new SqlCommand("USE master; IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name='filmapp') BEGIN DECLARE @s nvarchar(max)=N'CREATE LOGIN filmapp WITH PASSWORD='+QUOTENAME(@p,'''')+N',CHECK_POLICY=ON';EXEC(@s); END;",c)){cmd.Parameters.AddWithValue("@p",password);await cmd.ExecuteNonQueryAsync();}
 await RunFile(Path.Combine(root,"database","04_security.sql"));await RunFile(Path.Combine(root,"database","05_demo.sql"));
 Console.WriteLine("Database initialized. Run only once on a clean instance; no DROP is performed.");
}else if(mode=="test"){
 await RunFile(Path.Combine(root,"tests","01_workflow.sql"));Console.WriteLine("PASS SQL integration workflow and rejection tests");
}else throw new Exception("Use init or test");
