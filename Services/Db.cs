using System.Data;
using Microsoft.Data.SqlClient;
namespace FilmContest.Web.Services;
public sealed class Db(IConfiguration config)
{
 public async Task<DataTable> Query(string sql, params (string,object?)[] args) {
  await using var c=new SqlConnection(config.GetConnectionString("SqlServer"));
  await c.OpenAsync(); await using var cmd=c.CreateCommand();cmd.CommandText=sql;
  foreach(var (name,value) in args) cmd.Parameters.AddWithValue(name,value??DBNull.Value);
  await using var reader=await cmd.ExecuteReaderAsync();var t=new DataTable();t.Load(reader);return t;
 }
 public async Task<int> Exec(string sql, params (string,object?)[] args) {
  await using var c=new SqlConnection(config.GetConnectionString("SqlServer"));await c.OpenAsync();
  await using var cmd=c.CreateCommand();cmd.CommandText=sql;
  foreach(var (name,value) in args)cmd.Parameters.AddWithValue(name,value??DBNull.Value);
  return await cmd.ExecuteNonQueryAsync();
 }
 public async Task<object?> Scalar(string sql,params (string,object?)[] args) {
  var t=await Query(sql,args);return t.Rows.Count==0?null:t.Rows[0][0];
 }
}
