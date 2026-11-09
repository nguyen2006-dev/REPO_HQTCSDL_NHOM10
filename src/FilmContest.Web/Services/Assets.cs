using Azure.Storage.Blobs;
using SkiaSharp;
using System.Security.Cryptography;
namespace FilmContest.Web.Services;
public record StoredPhoto(string Key,string Sha256,string PerceptualHash,int Width,int Height);
public sealed class Assets(IConfiguration config,IWebHostEnvironment env) {
 private string Root=>Path.Combine(env.ContentRootPath,"App_Data","assets");
 private BlobContainerClient Container=>new(config["Storage:AzureConnectionString"],config["Storage:Container"]);
 public async Task<StoredPhoto> Save(IFormFile file) {
  if(file.Length==0||file.Length>10*1024*1024)throw new InvalidOperationException("Ảnh phải từ 1 byte đến 10 MB.");
  await using var input=file.OpenReadStream();using var raw=new MemoryStream();await input.CopyToAsync(raw);
  var bytes=raw.ToArray();using var encoded=new SKMemoryStream(bytes);using var codec=SKCodec.Create(encoded);
  if(codec==null||codec.EncodedFormat is not(SKEncodedImageFormat.Jpeg or SKEncodedImageFormat.Png))throw new InvalidOperationException("Chỉ nhận JPEG hoặc PNG hợp lệ.");
  var info=codec.Info;if(Math.Min(info.Width,info.Height)<600||Math.Max(info.Width,info.Height)<800||((long)info.Width*info.Height)>40000000)throw new InvalidOperationException("Cạnh ngắn ít nhất 600, cạnh dài ít nhất 800 pixel; tối đa 40 megapixel.");
  using var original=SKBitmap.Decode(codec)??throw new InvalidOperationException("Không giải mã được ảnh.");
  bool swap=codec.EncodedOrigin is SKEncodedOrigin.LeftTop or SKEncodedOrigin.RightTop or SKEncodedOrigin.RightBottom or SKEncodedOrigin.LeftBottom;
  var width=swap?original.Height:original.Width;var height=swap?original.Width:original.Height;
  using var normalized=new SKBitmap(width,height);using(var canvas=new SKCanvas(normalized)){
   canvas.Clear(SKColors.White);
   switch(codec.EncodedOrigin){
    case SKEncodedOrigin.TopRight:canvas.Translate(width,0);canvas.Scale(-1,1);break;
    case SKEncodedOrigin.BottomRight:canvas.Translate(width,height);canvas.RotateDegrees(180);break;
    case SKEncodedOrigin.BottomLeft:canvas.Translate(0,height);canvas.Scale(1,-1);break;
    case SKEncodedOrigin.LeftTop:canvas.RotateDegrees(90);canvas.Scale(1,-1);break;
    case SKEncodedOrigin.RightTop:canvas.Translate(width,0);canvas.RotateDegrees(90);break;
    case SKEncodedOrigin.RightBottom:canvas.Translate(width,height);canvas.RotateDegrees(90);canvas.Scale(-1,1);break;
    case SKEncodedOrigin.LeftBottom:canvas.Translate(0,height);canvas.RotateDegrees(270);break;
   }canvas.DrawBitmap(original,0,0);
  }
  using var small=new SKBitmap(9,8);using(var canvas=new SKCanvas(small))canvas.DrawBitmap(normalized,new SKRect(0,0,9,8));
  int Luma(SKColor c)=>299*c.Red+587*c.Green+114*c.Blue;
  ulong hash=0;int bit=0;for(int y=0;y<8;y++)for(int x=0;x<8;x++){if(Luma(small.GetPixel(x,y))>Luma(small.GetPixel(x+1,y)))hash|=1UL<<bit;bit++;}
  using var cleanImage=SKImage.FromBitmap(normalized);using var data=cleanImage.Encode(SKEncodedImageFormat.Jpeg,95);using var clean=new MemoryStream(data.ToArray());
  var key=Guid.NewGuid().ToString("N")+".jpg";
  if(config["Storage:Provider"]=="Azure")await Container.GetBlobClient(key).UploadAsync(clean,overwrite:false);
  else {Directory.CreateDirectory(Root);await using var output=File.Create(Path.Combine(Root,key));await clean.CopyToAsync(output);}
  return new(key,Convert.ToHexString(SHA256.HashData(bytes)),hash.ToString("X16"),width,height);
 }
 public async Task<Stream> Open(string key) {
  if(!System.Text.RegularExpressions.Regex.IsMatch(key,"^[a-f0-9]{32}\\.jpg$"))throw new InvalidOperationException("Invalid asset key");
  return config["Storage:Provider"]=="Azure"?await Container.GetBlobClient(key).OpenReadAsync():File.OpenRead(Path.Combine(Root,key));
 }
 public async Task Delete(string key) {if(config["Storage:Provider"]=="Azure")await Container.DeleteBlobIfExistsAsync(key);else File.Delete(Path.Combine(Root,key));}
}
