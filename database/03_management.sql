USE FilmContest;
GO
CREATE OR ALTER PROCEDURE dbo.usp_OpenContest @Actor int,@Contest int AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Contests WITH(UPDLOCK,HOLDLOCK) WHERE ContestId=@Contest AND Status='Draft' AND Closes>SYSUTCDATETIME() AND JudgingStart IS NOT NULL AND JudgingEnd IS NOT NULL AND(OwnerId=@Actor OR EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Admin')))THROW 51000,N'Không thể mở cuộc thi.',1;
 IF COALESCE((SELECT SUM(Weight)FROM dbo.Criteria WHERE ContestId=@Contest),0)<>1 THROW 51000,N'Tổng trọng số phải bằng 1.',1;
 UPDATE dbo.Contests SET Status='Open' WHERE ContestId=@Contest;COMMIT;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Configure @Actor int,@Contest int,@Operation varchar(30),@Name nvarchar(300),@Weight decimal(5,4) AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Contests WITH(UPDLOCK,HOLDLOCK) WHERE ContestId=@Contest AND Status='Draft' AND(OwnerId=@Actor OR EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Admin')))THROW 51000,N'Chỉ cấu hình cuộc thi nháp.',1;
 IF @Operation='category' INSERT dbo.Categories(ContestId,Name)VALUES(@Contest,@Name);
 ELSE IF @Operation='criterion' INSERT dbo.Criteria(ContestId,Name,Weight)VALUES(@Contest,@Name,@Weight);
 ELSE IF @Operation='clearcriteria' DELETE dbo.Criteria WHERE ContestId=@Contest;
 ELSE IF @Operation='award' INSERT dbo.Awards(ContestId,Name,Prize)VALUES(@Contest,@Name,N'Theo thể lệ cuộc thi');
 ELSE THROW 51000,N'Thao tác không hợp lệ.',1;
 COMMIT;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_CloneContest @Actor int,@Contest int AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Contests WITH(UPDLOCK,HOLDLOCK) WHERE ContestId=@Contest AND(OwnerId=@Actor OR EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Admin')))THROW 51000,N'Không có quyền sao chép.',1;
 INSERT dbo.Contests(OwnerId,Title,Rules,Opens,Closes,MaxEntries)SELECT @Actor,LEFT(Title,165)+N' (bản sao)',Rules,SYSUTCDATETIME(),DATEADD(day,30,SYSUTCDATETIME()),MaxEntries FROM dbo.Contests WHERE ContestId=@Contest;
 DECLARE @Id int=SCOPE_IDENTITY();
 UPDATE dbo.Contests SET JudgingStart=DATEADD(minute,1,Closes),JudgingEnd=DATEADD(day,14,Closes) WHERE ContestId=@Id;
 INSERT dbo.Categories(ContestId,Name)SELECT @Id,Name FROM dbo.Categories WHERE ContestId=@Contest;
 INSERT dbo.Criteria(ContestId,Name,Weight)SELECT @Id,Name,Weight FROM dbo.Criteria WHERE ContestId=@Contest;
 INSERT dbo.Awards(ContestId,Name,Prize)SELECT @Id,Name,Prize FROM dbo.Awards WHERE ContestId=@Contest;
 INSERT dbo.JudgingRounds(ContestId,Name,RoundNumber)VALUES(@Id,N'Vòng 1',1);
 COMMIT;SELECT @Id;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_RoundAction @Actor int,@Contest int,@Round int,@Operation varchar(20) AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Contests WITH(UPDLOCK,HOLDLOCK) WHERE ContestId=@Contest AND Status='Judging' AND(OwnerId=@Actor OR EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Admin')))THROW 51000,N'Không có quyền quản lý vòng.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.JudgingRounds WHERE RoundId=@Round AND ContestId=@Contest)THROW 51000,N'Vòng không hợp lệ.',1;
 IF @Operation='close' EXEC dbo.usp_CloseRound @Actor,@Round;
 ELSE IF @Operation='next' BEGIN
 IF EXISTS(SELECT 1 FROM dbo.JudgingRounds WHERE ContestId=@Contest AND State<>'Closed')THROW 51000,N'Cần đóng các vòng trước.',1;
 DECLARE @N int=(SELECT MAX(RoundNumber)+1 FROM dbo.JudgingRounds WHERE ContestId=@Contest);
 INSERT dbo.JudgingRounds(ContestId,Name,RoundNumber,State)VALUES(@Contest,CONCAT(N'Vòng ',@N),@N,'Open');END
 ELSE THROW 51000,N'Thao tác không hợp lệ.',1;
 COMMIT;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Award @Actor int,@Contest int,@Award int,@Submission int AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Contests WITH(UPDLOCK,HOLDLOCK) WHERE ContestId=@Contest AND Status='Judging' AND(OwnerId=@Actor OR EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Admin')))THROW 51000,N'Không thể trao giải.',1;
 IF EXISTS(SELECT 1 FROM dbo.JudgingRounds WHERE ContestId=@Contest AND State<>'Closed')THROW 51000,N'Cần hoàn tất mọi vòng chấm.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Awards WHERE AwardId=@Award AND ContestId=@Contest)OR NOT EXISTS(SELECT 1 FROM dbo.v_Rankings WHERE ContestId=@Contest AND SubmissionId=@Submission)THROW 51000,N'Giải hoặc bài dự thi không hợp lệ.',1;
 INSERT dbo.SubmissionAwards(AwardId,SubmissionId)VALUES(@Award,@Submission);COMMIT;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_ChangeUser @Actor int,@Target int,@Role varchar(20),@Active bit AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Users WITH(UPDLOCK,HOLDLOCK) WHERE UserId=@Actor AND Role='Admin' AND Active=1)THROW 51000,N'Không có quyền quản trị.',1;
 IF @Actor=@Target THROW 51000,N'Không tự thay đổi quyền hoặc khóa tài khoản quản trị đang dùng.',1;
 -- Preserve historical judge identity: do not change a judge with assignments to another role.
 IF @Role<>'Judge' AND EXISTS(SELECT 1 FROM dbo.JudgeAssignments WHERE JudgeId=@Target)THROW 51000,N'Giám khảo đã có phân công; có thể khóa thay vì đổi vai trò.',1;
 UPDATE dbo.Users SET Role=@Role,Active=@Active,TokenVersion=TokenVersion+1 WHERE UserId=@Target;
 INSERT dbo.AuditLog(ActorId,Action,EntityId,Detail)VALUES(@Actor,'ChangeUser',@Target,CONCAT(@Role,' Active=',@Active));COMMIT;END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Schedule @Actor int,@Contest int,@Start datetime2,@End datetime2 AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Contests WITH(UPDLOCK,HOLDLOCK) WHERE ContestId=@Contest AND Status IN('Draft','Judging') AND(OwnerId=@Actor OR EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Admin')))THROW 51000,N'Không được đổi lịch chấm.',1;
 UPDATE dbo.Contests SET JudgingStart=@Start,JudgingEnd=@End WHERE ContestId=@Contest;
 INSERT dbo.AuditLog(ActorId,Action,EntityId,Detail)VALUES(@Actor,'Schedule',@Contest,N'Cập nhật lịch chấm UTC');COMMIT;END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AddStock @Actor int,@Brand nvarchar(80),@Name nvarchar(100),@ISO int AS
BEGIN
 IF NOT EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Admin' AND Active=1)THROW 51000,N'Không có quyền.',1;
 INSERT dbo.FilmStocks(Brand,Name,DefaultISO)VALUES(@Brand,@Name,@ISO);
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_SetSetting @Actor int,@Key varchar(40),@Value nvarchar(1000) AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Admin' AND Active=1)THROW 51000,N'Không có quyền.',1;
 IF @Key NOT IN('Banner','RequireNegative') OR (@Key='RequireNegative' AND @Value NOT IN('0','1'))THROW 51000,N'Cấu hình không hợp lệ.',1;
 UPDATE dbo.PlatformSettings SET SettingValue=@Value WHERE SettingKey=@Key;
 INSERT dbo.AuditLog(ActorId,Action,EntityId,Detail)VALUES(@Actor,'SystemSetting',0,CONCAT(@Key,': ',@Value));COMMIT;END;
GO
