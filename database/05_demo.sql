USE FilmContest;
GO
-- No shared passwords. These sample records cannot log in until deliberately provisioned.
-- Create real demo accounts via website and assign roles from Admin UI.
IF NOT EXISTS(SELECT 1 FROM dbo.Users WHERE Email='sample-organizer@example.invalid')
 INSERT dbo.Users(Email,Name,PasswordHash,Role,Active)VALUES('sample-organizer@example.invalid',N'Ban tổ chức mẫu','DISABLED','Organizer',0);
DECLARE @Organizer int=(SELECT UserId FROM dbo.Users WHERE Email='sample-organizer@example.invalid');
IF NOT EXISTS(SELECT 1 FROM dbo.Contests WHERE Title=N'Ký ức trên phim · dữ liệu minh họa') BEGIN
 INSERT dbo.Contests(OwnerId,Title,Rules,Opens,Closes,MaxEntries,Status)
 VALUES(@Organizer,N'Ký ức trên phim · dữ liệu minh họa',N'Ảnh chụp bằng phim, tác giả sở hữu tác phẩm. Tối đa 5 ảnh/người. Chỉ dùng dữ liệu minh họa; quản trị viên có thể sao chép thành cuộc thi mới.',SYSUTCDATETIME(),DATEADD(day,30,SYSUTCDATETIME()),5,'Open');
 DECLARE @Contest int=SCOPE_IDENTITY();
 UPDATE dbo.Contests SET JudgingStart=DATEADD(minute,1,Closes),JudgingEnd=DATEADD(day,14,Closes) WHERE ContestId=@Contest;
 INSERT dbo.Categories(ContestId,Name)VALUES(@Contest,N'Đời sống'),(@Contest,N'Phong cảnh');
 INSERT dbo.Criteria(ContestId,Name,Weight)VALUES(@Contest,N'Bố cục',0.3),(@Contest,N'Câu chuyện',0.4),(@Contest,N'Kỹ thuật phim',0.3);
 INSERT dbo.JudgingRounds(ContestId,Name,RoundNumber)VALUES(@Contest,N'Vòng 1',1);
 INSERT dbo.Awards(ContestId,Name,Prize)VALUES(@Contest,N'Giải Nhất',N'Chứng nhận'),(@Contest,N'Giải Nhì',N'Chứng nhận');END;
GO
