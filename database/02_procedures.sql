USE FilmContest;
GO
CREATE OR ALTER PROCEDURE dbo.usp_BootstrapAdmin @Email nvarchar(254),@Hash nvarchar(500) AS
BEGIN SET XACT_ABORT ON; BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Users WITH(UPDLOCK,HOLDLOCK) WHERE Role='Admin')
 INSERT dbo.Users(Email,Name,PasswordHash,Role) VALUES(@Email,N'Quản trị viên',@Hash,'Admin');
 COMMIT; END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_CreateContest @Actor int,@Title nvarchar(180),@Rules nvarchar(4000),@Opens datetime2,@Closes datetime2,@Max int,@Category nvarchar(120) AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Active=1 AND Role IN('Organizer','Admin')) THROW 51000,N'Không có quyền tạo cuộc thi.',1;
 INSERT dbo.Contests(OwnerId,Title,Rules,Opens,Closes,MaxEntries) VALUES(@Actor,@Title,@Rules,@Opens,@Closes,@Max);
 DECLARE @Id int=SCOPE_IDENTITY();
 UPDATE dbo.Contests SET JudgingStart=DATEADD(minute,1,@Closes),JudgingEnd=DATEADD(day,14,@Closes) WHERE ContestId=@Id;
 INSERT dbo.Categories(ContestId,Name) VALUES(@Id,@Category);
 INSERT dbo.Criteria(ContestId,Name,Weight) VALUES(@Id,N'Bố cục',0.3),(@Id,N'Sáng tạo và câu chuyện',0.4),(@Id,N'Kỹ thuật ảnh phim',0.3);
 INSERT dbo.JudgingRounds(ContestId,Name,RoundNumber) VALUES(@Id,N'Vòng chung kết',1);
 INSERT dbo.AuditLog(ActorId,Action,EntityId,Detail) VALUES(@Actor,'CreateContest',@Id,@Title);
 COMMIT;SELECT @Id AS ContestId;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_RegisterContest @Actor int,@Contest int AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Participant' AND Active=1) THROW 51000,N'Chỉ người dự thi được đăng ký.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Contests WITH(UPDLOCK,HOLDLOCK) WHERE ContestId=@Contest AND Status='Open' AND SYSUTCDATETIME() BETWEEN Opens AND Closes) THROW 51000,N'Cuộc thi chưa mở hoặc đã hết hạn.',1;
 IF EXISTS(SELECT 1 FROM dbo.Registrations WHERE ContestId=@Contest AND UserId=@Actor) THROW 51000,N'Bạn đã đăng ký.',1;
 INSERT dbo.Registrations(ContestId,UserId)VALUES(@Contest,@Actor);COMMIT;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Submit @Actor int,@Contest int,@Category int,@Roll int,@Frame int,@Title nvarchar(180),@Location nvarchar(300),@Scan nvarchar(1000),@Negative nvarchar(500),@Key varchar(40),@Sha char(64),@PHash char(16),@Width int,@Height int AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 DECLARE @Max int;
 SELECT @Max=MaxEntries FROM dbo.Contests WITH(UPDLOCK,HOLDLOCK) WHERE ContestId=@Contest AND Status='Open' AND SYSUTCDATETIME() BETWEEN Opens AND Closes;
 IF @Max IS NULL THROW 51000,N'Cuộc thi chưa mở hoặc đã hết hạn.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Registrations WHERE ContestId=@Contest AND UserId=@Actor) THROW 51000,N'Bạn chưa đăng ký cuộc thi.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.FilmRolls WHERE RollId=@Roll AND UserId=@Actor) THROW 51000,N'Cuộn phim không thuộc tài khoản.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Categories WHERE CategoryId=@Category AND ContestId=@Contest) THROW 51000,N'Hạng mục không hợp lệ.',1;
 IF(SELECT COUNT(*) FROM dbo.Submissions WHERE ContestId=@Contest AND UserId=@Actor)>=@Max THROW 51000,N'Đã đạt giới hạn số bài.',1;
 IF EXISTS(SELECT 1 FROM dbo.PlatformSettings WHERE SettingKey='RequireNegative' AND SettingValue='1') AND LEN(LTRIM(RTRIM(@Negative)))=0 THROW 51000,N'Hệ thống yêu cầu mã tham chiếu âm bản.',1;
 IF LEN(LTRIM(RTRIM(@Scan)))=0 THROW 51000,N'Thiếu thông số scan.',1;
 DECLARE @FrameId int=(SELECT FrameId FROM dbo.Frames WHERE RollId=@Roll AND FrameNumber=@Frame);
 IF @FrameId IS NULL BEGIN
 INSERT dbo.Frames(RollId,FrameNumber,Location,ScanSpecs,NegativeReference)VALUES(@Roll,@Frame,@Location,@Scan,@Negative);SET @FrameId=SCOPE_IDENTITY();END;
 INSERT dbo.Submissions(ContestId,CategoryId,UserId,FrameId,Title,AssetKey,Sha256,PHash,Width,Height)VALUES(@Contest,@Category,@Actor,@FrameId,@Title,@Key,@Sha,@PHash,@Width,@Height);
 DECLARE @Id int=SCOPE_IDENTITY();INSERT dbo.AuditLog(ActorId,Action,EntityId,Detail)VALUES(@Actor,'Submit',@Id,@Title);COMMIT;SELECT @Id;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Review @Actor int,@Submission int,@Decision varchar(20),@Reason nvarchar(1000) AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Submissions s JOIN dbo.Contests c WITH(UPDLOCK,HOLDLOCK) ON c.ContestId=s.ContestId WHERE s.SubmissionId=@Submission AND c.Status IN('Open','Draft') AND(c.OwnerId=@Actor OR EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Admin'))) THROW 51000,N'Không có quyền duyệt hoặc cuộc thi đã khóa.',1;
 IF LEN(LTRIM(RTRIM(@Reason)))=0 THROW 51000,N'Cần ghi lý do quyết định.',1;
 UPDATE dbo.Submissions SET Status=@Decision WHERE SubmissionId=@Submission;
 INSERT dbo.SubmissionReviews(SubmissionId,ReviewerId,Decision,Reason)VALUES(@Submission,@Actor,@Decision,@Reason);COMMIT;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_StartJudging @Actor int,@Contest int AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Contests WITH(UPDLOCK,HOLDLOCK) WHERE ContestId=@Contest AND Status='Open' AND Closes<SYSUTCDATETIME() AND SYSUTCDATETIME() BETWEEN JudgingStart AND JudgingEnd AND(OwnerId=@Actor OR EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Admin')))THROW 51000,N'Chỉ bắt đầu chấm sau hạn nhận bài.',1;
 IF EXISTS(SELECT 1 FROM dbo.Submissions WHERE ContestId=@Contest AND Status='Pending')THROW 51000,N'Còn bài chờ duyệt.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Submissions WHERE ContestId=@Contest AND Status='Approved')THROW 51000,N'Chưa có bài hợp lệ.',1;
 IF(SELECT SUM(Weight) FROM dbo.Criteria WHERE ContestId=@Contest)<>1 THROW 51000,N'Tổng trọng số phải bằng 1.',1;
 UPDATE dbo.Contests SET Status='Judging' WHERE ContestId=@Contest;
 UPDATE dbo.JudgingRounds SET State='Open' WHERE ContestId=@Contest AND RoundNumber=1;COMMIT;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Assign @Actor int,@Round int,@Submission int,@Judge int AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.JudgingRounds r JOIN dbo.Contests c WITH(UPDLOCK,HOLDLOCK) ON c.ContestId=r.ContestId JOIN dbo.Submissions s ON s.ContestId=c.ContestId AND s.SubmissionId=@Submission WHERE r.RoundId=@Round AND r.State IN('Draft','Open') AND c.Status='Judging' AND s.Status='Approved' AND s.UserId<>@Judge AND(c.OwnerId=@Actor OR EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Admin')))THROW 51000,N'Phân công không hợp lệ.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Judge AND Role='Judge' AND Active=1)THROW 51000,N'Tài khoản không phải giám khảo.',1;
 INSERT dbo.JudgeAssignments(RoundId,SubmissionId,JudgeId)VALUES(@Round,@Submission,@Judge);COMMIT;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Score @Actor int,@Assignment int,@Criterion int,@Score decimal(4,2),@Comment nvarchar(1000) AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.JudgeAssignments a WITH(UPDLOCK,HOLDLOCK) JOIN dbo.JudgingRounds r ON r.RoundId=a.RoundId JOIN dbo.Contests c WITH(UPDLOCK,HOLDLOCK) ON c.ContestId=r.ContestId JOIN dbo.Criteria cr ON cr.ContestId=c.ContestId WHERE a.AssignmentId=@Assignment AND a.JudgeId=@Actor AND a.Finalized=0 AND r.State='Open' AND c.Status='Judging' AND SYSUTCDATETIME() BETWEEN c.JudgingStart AND c.JudgingEnd AND cr.CriterionId=@Criterion)THROW 51000,N'Không được chấm bài hoặc tiêu chí này.',1;
 IF EXISTS(SELECT 1 FROM dbo.Scores WHERE AssignmentId=@Assignment AND CriterionId=@Criterion)
 UPDATE dbo.Scores SET Score=@Score,Comment=@Comment,UpdatedAt=SYSUTCDATETIME()WHERE AssignmentId=@Assignment AND CriterionId=@Criterion;
 ELSE INSERT dbo.Scores(AssignmentId,CriterionId,Score,Comment)VALUES(@Assignment,@Criterion,@Score,@Comment);COMMIT;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_FinalizeScore @Actor int,@Assignment int AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 DECLARE @Contest int;
 SELECT @Contest=r.ContestId FROM dbo.JudgeAssignments a WITH(UPDLOCK,HOLDLOCK) JOIN dbo.JudgingRounds r ON r.RoundId=a.RoundId JOIN dbo.Contests c WITH(UPDLOCK,HOLDLOCK) ON c.ContestId=r.ContestId WHERE a.AssignmentId=@Assignment AND a.JudgeId=@Actor AND a.Finalized=0 AND r.State='Open' AND c.Status='Judging';
 IF @Contest IS NULL THROW 51000,N'Không được xác nhận bài này.',1;
 IF(SELECT COUNT(*)FROM dbo.Scores WHERE AssignmentId=@Assignment)<>(SELECT COUNT(*)FROM dbo.Criteria WHERE ContestId=@Contest)THROW 51000,N'Chưa chấm đủ tiêu chí.',1;
 UPDATE dbo.JudgeAssignments SET Finalized=1 WHERE AssignmentId=@Assignment;COMMIT;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_CloseRound @Actor int,@Round int AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 DECLARE @Contest int;
 SELECT @Contest=c.ContestId FROM dbo.JudgingRounds r JOIN dbo.Contests c WITH(UPDLOCK,HOLDLOCK) ON c.ContestId=r.ContestId WHERE r.RoundId=@Round AND r.State='Open' AND c.Status='Judging' AND(c.OwnerId=@Actor OR EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Admin'));
 IF @Contest IS NULL THROW 51000,N'Không có quyền đóng vòng.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.JudgeAssignments WHERE RoundId=@Round)OR EXISTS(SELECT 1 FROM dbo.JudgeAssignments WHERE RoundId=@Round AND Finalized=0)THROW 51000,N'Chưa hoàn tất chấm vòng.',1;
 IF EXISTS(SELECT 1 FROM dbo.Submissions s WHERE s.ContestId=@Contest AND s.Status='Approved' AND NOT EXISTS(SELECT 1 FROM dbo.JudgeAssignments a WHERE a.SubmissionId=s.SubmissionId AND a.RoundId=@Round))THROW 51000,N'Có bài chưa được phân công trong vòng.',1;
 UPDATE dbo.JudgingRounds SET State='Closed' WHERE RoundId=@Round;COMMIT;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Publish @Actor int,@Contest int AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Contests WITH(UPDLOCK,HOLDLOCK) WHERE ContestId=@Contest AND Status='Judging' AND(OwnerId=@Actor OR EXISTS(SELECT 1 FROM dbo.Users WHERE UserId=@Actor AND Role='Admin')))THROW 51000,N'Không được công bố.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.JudgingRounds WHERE ContestId=@Contest)OR EXISTS(SELECT 1 FROM dbo.JudgingRounds WHERE ContestId=@Contest AND State<>'Closed')THROW 51000,N'Cần đóng tất cả vòng chấm.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.SubmissionAwards sa JOIN dbo.Awards a ON a.AwardId=sa.AwardId WHERE a.ContestId=@Contest)THROW 51000,N'Cần trao ít nhất một giải trước khi công bố.',1;
 UPDATE dbo.Contests SET Status='Published' WHERE ContestId=@Contest;
 INSERT dbo.AuditLog(ActorId,Action,EntityId,Detail)VALUES(@Actor,'Publish',@Contest,N'Công bố kết quả');COMMIT;END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_SaveAICheck @id int,@kind varchar(30),@status varchar(20),@score decimal(6,5),@detail nvarchar(2000),@version nvarchar(120) AS
BEGIN SET XACT_ABORT ON;BEGIN TRAN;
 IF EXISTS(SELECT 1 FROM dbo.AICheckResults WITH(UPDLOCK,HOLDLOCK) WHERE SubmissionId=@id AND Kind=@kind)
 UPDATE dbo.AICheckResults SET Status=@status,Score=@score,Detail=@detail,ModelVersion=@version,CheckedAt=SYSUTCDATETIME()WHERE SubmissionId=@id AND Kind=@kind;
 ELSE INSERT dbo.AICheckResults(SubmissionId,Kind,Status,Score,Detail,ModelVersion)VALUES(@id,@kind,@status,@score,@detail,@version);COMMIT;END;
GO
