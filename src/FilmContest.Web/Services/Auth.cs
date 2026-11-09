using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
namespace FilmContest.Web.Services;
public sealed class Tokens(IConfiguration config) {
 public string Create(int id,string name,string role,int version) {
  var claims=new[]{new Claim(ClaimTypes.NameIdentifier,id.ToString()),new Claim(ClaimTypes.Name,name),new Claim(ClaimTypes.Role,role),new Claim("ver",version.ToString())};
  return new JwtSecurityTokenHandler().WriteToken(new JwtSecurityToken(config["Jwt:Issuer"],config["Jwt:Audience"],claims,expires:DateTime.UtcNow.AddHours(2),signingCredentials:new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(config["Jwt:Key"]!)),SecurityAlgorithms.HmacSha256)));
 }
}
public static class IdentityExtensions { public static int UserId(this ClaimsPrincipal user)=>int.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!); }
