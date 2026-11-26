using System.ComponentModel.DataAnnotations;
namespace FilmContest.Web.Models;
public class LoginForm { [Required,EmailAddress,StringLength(254)] public string Email{get;set;}=""; [Required,StringLength(128),DataType(DataType.Password)] public string Password{get;set;}=""; }
public class RegisterForm:LoginForm,IValidatableObject { public IEnumerable<ValidationResult> Validate(ValidationContext context) { if(string.IsNullOrEmpty(Password)||Password.Length<12) yield return new ValidationResult("Mật khẩu tối thiểu 12 ký tự.",new[]{nameof(Password)}); } [Required,StringLength(120)] public string Name{get;set;}=""; }
public class ContestForm:IValidatableObject {
 public IEnumerable<ValidationResult> Validate(ValidationContext context) { if(Opens>=Closes) yield return new ValidationResult("Ngày đóng phải sau ngày mở.",new[]{nameof(Closes)}); }
 [Required,StringLength(180)] public string Title{get;set;}="";
 [Required,StringLength(4000)] public string Rules{get;set;}="";
 public DateTime Opens{get;set;}=DateTime.UtcNow;
 public DateTime Closes{get;set;}=DateTime.UtcNow.AddDays(30);
 [Range(1,100)] public int MaxEntries{get;set;}=5;
 [Required,StringLength(120)] public string Category{get;set;}="Ảnh phim";
}
public class RollForm {
 [Required,StringLength(100)]public string Name{get;set;}="";
 [Range(1,int.MaxValue)]public int StockId{get;set;}
 [Range(1,102400)]public int ISO{get;set;}=200;
 [Required,StringLength(100)]public string Camera{get;set;}="";
 [Required,StringLength(100)]public string Lens{get;set;}="";
 [Required,StringLength(40)] public string Format{get;set;}="35mm";
 [StringLength(180)] public string? Lab{get;set;}="";
}
public class SubmissionForm {
 [Range(1,int.MaxValue)] public int ContestId{get;set;} [Range(1,int.MaxValue)] public int CategoryId{get;set;} [Range(1,int.MaxValue)] public int RollId{get;set;}
 [Required,StringLength(180)]public string Title{get;set;}="";
 [Range(1,1000)]public int FrameNumber{get;set;}=1;
 [StringLength(300)] public string? Location{get;set;}="";
 [Required,StringLength(1000)]public string ScanSpecs{get;set;}="";
 [StringLength(500)] public string? NegativeReference{get;set;}="";
 [Required]public IFormFile Photo{get;set;}=null!;
}
