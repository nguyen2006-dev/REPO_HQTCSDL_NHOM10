using System.ComponentModel.DataAnnotations;
namespace FilmContest.Web.Models;
public class LoginForm { [Required,EmailAddress] public string Email{get;set;}=""; [Required,DataType(DataType.Password)] public string Password{get;set;}=""; }
public class RegisterForm:LoginForm { [Required,StringLength(120)] public string Name{get;set;}=""; }
public class ContestForm {
 [Required,StringLength(180)] public string Title{get;set;}="";
 [Required,StringLength(4000)] public string Rules{get;set;}="";
 public DateTime Opens{get;set;}=DateTime.UtcNow;
 public DateTime Closes{get;set;}=DateTime.UtcNow.AddDays(30);
 [Range(1,100)] public int MaxEntries{get;set;}=5;
 public string Category{get;set;}="Ảnh phim";
}
public class RollForm {
 [Required,StringLength(100)]public string Name{get;set;}="";
 [Range(1,int.MaxValue)]public int StockId{get;set;}
 [Range(1,102400)]public int ISO{get;set;}=200;
 [Required,StringLength(100)]public string Camera{get;set;}="";
 [Required,StringLength(100)]public string Lens{get;set;}="";
 public string Format{get;set;}="35mm";
 public string Lab{get;set;}="";
}
public class SubmissionForm {
 public int ContestId{get;set;} public int CategoryId{get;set;} public int RollId{get;set;}
 [Required,StringLength(180)]public string Title{get;set;}="";
 [Range(1,1000)]public int FrameNumber{get;set;}=1;
 public string Location{get;set;}="";
 [Required,StringLength(1000)]public string ScanSpecs{get;set;}="";
 public string NegativeReference{get;set;}="";
 [Required]public IFormFile Photo{get;set;}=null!;
}
