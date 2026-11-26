USE FilmContest;
GO
-- Run against an isolated development/test database with DBA permission.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRAN;
 DECLARE @Suffix varchar(36)=CONVERT(varchar(36),NEWID());
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('o-',@Suffix,'@test.invalid'),N'Organizer test','disabled','Organizer');DECLARE @O int=SCOPE_IDENTITY();
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('p-',@Suffix,'@test.invalid'),N'Participant test','disabled','Participant');DECLARE @P int=SCOPE_IDENTITY();
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('j-',@Suffix,'@test.invalid'),N'Judge test','disabled','Judge');DECLARE @J int=SCOPE_IDENTITY();
 DECLARE @Created table(Id int);DECLARE @Open datetime2=DATEADD(day,-1,SYSUTCDATETIME()),@Close datetime2=DATEADD(day,1,SYSUTCDATETIME());
 INSERT @Created EXEC dbo.usp_CreateContest @O,N'Integration test',N'Film only',@Open,@Close,5,N'Landscape';
 DECLARE @C int=(SELECT Id FROM @Created);
 EXEC dbo.usp_Configure @O,@C,'award',N'First prize',0;
 EXEC dbo.usp_OpenContest @O,@C;
 EXEC dbo.usp_RegisterContest @P,@C;
 DECLARE @Stock int=(SELECT MIN(StockId) FROM dbo.FilmStocks);
 INSERT dbo.FilmRolls(UserId,Name,StockId,Stock,ISO,Camera,Lens,Format,Lab)VALUES(@P,'roll',@Stock,'Kodak Gold',200,'Nikon','50mm','35mm','Lab');DECLARE @Roll int=SCOPE_IDENTITY();
 DECLARE @Cat int=(SELECT CategoryId FROM dbo.Categories WHERE ContestId=@C);
 DECLARE @Submitted table(Id int);
 INSERT @Submitted EXEC dbo.usp_Submit @P,@C,@Cat,@Roll,1,N'Test frame',N'VN',N'2400dpi','negative-1','00000000000000000000000000000001.jpg','AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','0000000000000000',800,600;
 DECLARE @S int=(SELECT Id FROM @Submitted);

 EXEC dbo.usp_Submit @P,@C,@Cat,@Roll,2,N'Duplicate',N'VN',N'2400dpi','n','00000000000000000000000000000002.jpg','AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','0000000000000000',800,600;
 THROW 52000,'FAIL: duplicate SHA256 accepted',1;
END TRY
BEGIN CATCH
 DECLARE @Error int=ERROR_NUMBER();
 IF @@TRANCOUNT>0 ROLLBACK;
 IF @Error NOT IN(2601,2627) THROW;
 PRINT 'PASS: duplicate SHA256 rejected';
END CATCH;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRAN;
 DECLARE @Suffix varchar(36)=CONVERT(varchar(36),NEWID());
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('o-',@Suffix,'@test.invalid'),N'Organizer test','disabled','Organizer');DECLARE @O int=SCOPE_IDENTITY();
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('p-',@Suffix,'@test.invalid'),N'Participant test','disabled','Participant');DECLARE @P int=SCOPE_IDENTITY();
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('j-',@Suffix,'@test.invalid'),N'Judge test','disabled','Judge');DECLARE @J int=SCOPE_IDENTITY();
 DECLARE @Created table(Id int);DECLARE @Open datetime2=DATEADD(day,-1,SYSUTCDATETIME()),@Close datetime2=DATEADD(day,1,SYSUTCDATETIME());
 INSERT @Created EXEC dbo.usp_CreateContest @O,N'Integration test',N'Film only',@Open,@Close,5,N'Landscape';
 DECLARE @C int=(SELECT Id FROM @Created);
 EXEC dbo.usp_Configure @O,@C,'award',N'First prize',0;
 EXEC dbo.usp_OpenContest @O,@C;
 EXEC dbo.usp_RegisterContest @P,@C;
 DECLARE @Stock int=(SELECT MIN(StockId) FROM dbo.FilmStocks);
 INSERT dbo.FilmRolls(UserId,Name,StockId,Stock,ISO,Camera,Lens,Format,Lab)VALUES(@P,'roll',@Stock,'Kodak Gold',200,'Nikon','50mm','35mm','Lab');DECLARE @Roll int=SCOPE_IDENTITY();
 DECLARE @Cat int=(SELECT CategoryId FROM dbo.Categories WHERE ContestId=@C);
 DECLARE @Submitted table(Id int);
 INSERT @Submitted EXEC dbo.usp_Submit @P,@C,@Cat,@Roll,1,N'Test frame',N'VN',N'2400dpi','negative-1','00000000000000000000000000000001.jpg','AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','0000000000000000',800,600;
 DECLARE @S int=(SELECT Id FROM @Submitted);

 UPDATE dbo.Contests SET MaxEntries=1 WHERE ContestId=@C;
 EXEC dbo.usp_Submit @P,@C,@Cat,@Roll,2,N'Limit',N'VN',N'2400dpi','n','00000000000000000000000000000002.jpg','BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB','0000000000000000',800,600;
 THROW 52000,'FAIL: maximum entries accepted',1;
END TRY
BEGIN CATCH
 DECLARE @Error int=ERROR_NUMBER();
 IF @@TRANCOUNT>0 ROLLBACK;
 IF @Error NOT IN(51000) THROW;
 PRINT 'PASS: maximum entries rejected';
END CATCH;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRAN;
 DECLARE @Suffix varchar(36)=CONVERT(varchar(36),NEWID());
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('o-',@Suffix,'@test.invalid'),N'Organizer test','disabled','Organizer');DECLARE @O int=SCOPE_IDENTITY();
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('p-',@Suffix,'@test.invalid'),N'Participant test','disabled','Participant');DECLARE @P int=SCOPE_IDENTITY();
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('j-',@Suffix,'@test.invalid'),N'Judge test','disabled','Judge');DECLARE @J int=SCOPE_IDENTITY();
 DECLARE @Created table(Id int);DECLARE @Open datetime2=DATEADD(day,-1,SYSUTCDATETIME()),@Close datetime2=DATEADD(day,1,SYSUTCDATETIME());
 INSERT @Created EXEC dbo.usp_CreateContest @O,N'Integration test',N'Film only',@Open,@Close,5,N'Landscape';
 DECLARE @C int=(SELECT Id FROM @Created);
 EXEC dbo.usp_Configure @O,@C,'award',N'First prize',0;
 EXEC dbo.usp_OpenContest @O,@C;
 EXEC dbo.usp_RegisterContest @P,@C;
 DECLARE @Stock int=(SELECT MIN(StockId) FROM dbo.FilmStocks);
 INSERT dbo.FilmRolls(UserId,Name,StockId,Stock,ISO,Camera,Lens,Format,Lab)VALUES(@P,'roll',@Stock,'Kodak Gold',200,'Nikon','50mm','35mm','Lab');DECLARE @Roll int=SCOPE_IDENTITY();
 DECLARE @Cat int=(SELECT CategoryId FROM dbo.Categories WHERE ContestId=@C);
 DECLARE @Submitted table(Id int);
 INSERT @Submitted EXEC dbo.usp_Submit @P,@C,@Cat,@Roll,1,N'Test frame',N'VN',N'2400dpi','negative-1','00000000000000000000000000000001.jpg','AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','0000000000000000',800,600;
 DECLARE @S int=(SELECT Id FROM @Submitted);

 UPDATE dbo.Contests SET JudgingEnd=NULL WHERE ContestId=@C;
 THROW 52000,'FAIL: partial judging dates accepted',1;
END TRY
BEGIN CATCH
 DECLARE @Error int=ERROR_NUMBER();
 IF @@TRANCOUNT>0 ROLLBACK;
 IF @Error NOT IN(547) THROW;
 PRINT 'PASS: partial judging dates rejected';
END CATCH;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRAN;
 DECLARE @Suffix varchar(36)=CONVERT(varchar(36),NEWID());
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('o-',@Suffix,'@test.invalid'),N'Organizer test','disabled','Organizer');DECLARE @O int=SCOPE_IDENTITY();
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('p-',@Suffix,'@test.invalid'),N'Participant test','disabled','Participant');DECLARE @P int=SCOPE_IDENTITY();
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('j-',@Suffix,'@test.invalid'),N'Judge test','disabled','Judge');DECLARE @J int=SCOPE_IDENTITY();
 DECLARE @Created table(Id int);DECLARE @Open datetime2=DATEADD(day,-1,SYSUTCDATETIME()),@Close datetime2=DATEADD(day,1,SYSUTCDATETIME());
 INSERT @Created EXEC dbo.usp_CreateContest @O,N'Integration test',N'Film only',@Open,@Close,5,N'Landscape';
 DECLARE @C int=(SELECT Id FROM @Created);
 EXEC dbo.usp_Configure @O,@C,'award',N'First prize',0;
 EXEC dbo.usp_OpenContest @O,@C;
 EXEC dbo.usp_RegisterContest @P,@C;
 DECLARE @Stock int=(SELECT MIN(StockId) FROM dbo.FilmStocks);
 INSERT dbo.FilmRolls(UserId,Name,StockId,Stock,ISO,Camera,Lens,Format,Lab)VALUES(@P,'roll',@Stock,'Kodak Gold',200,'Nikon','50mm','35mm','Lab');DECLARE @Roll int=SCOPE_IDENTITY();
 DECLARE @Cat int=(SELECT CategoryId FROM dbo.Categories WHERE ContestId=@C);
 DECLARE @Submitted table(Id int);
 INSERT @Submitted EXEC dbo.usp_Submit @P,@C,@Cat,@Roll,1,N'Test frame',N'VN',N'2400dpi','negative-1','00000000000000000000000000000001.jpg','AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','0000000000000000',800,600;
 DECLARE @S int=(SELECT Id FROM @Submitted);

 EXEC dbo.usp_Review @O,@S,'Approved',N'Checked';
 UPDATE dbo.Contests SET Closes=DATEADD(minute,-2,SYSUTCDATETIME()),JudgingStart=DATEADD(minute,-1,SYSUTCDATETIME()),JudgingEnd=DATEADD(day,1,SYSUTCDATETIME()) WHERE ContestId=@C;
 EXEC dbo.usp_StartJudging @O,@C;
 DECLARE @Round int=(SELECT RoundId FROM dbo.JudgingRounds WHERE ContestId=@C);
 EXEC dbo.usp_Assign @O,@Round,@S,@J;
 DECLARE @A int=(SELECT AssignmentId FROM dbo.JudgeAssignments WHERE SubmissionId=@S);
 DECLARE @Criterion int=(SELECT MIN(CriterionId) FROM dbo.Criteria WHERE ContestId=@C);

 EXEC dbo.usp_Score @J,@A,@Criterion,11,N'Invalid';
 THROW 52000,'FAIL: out of range assigned score accepted',1;
END TRY
BEGIN CATCH
 DECLARE @Error int=ERROR_NUMBER();
 IF @@TRANCOUNT>0 ROLLBACK;
 IF @Error NOT IN(51000) THROW;
 PRINT 'PASS: out of range assigned score rejected';
END CATCH;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRAN;
 DECLARE @Suffix varchar(36)=CONVERT(varchar(36),NEWID());
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('o-',@Suffix,'@test.invalid'),N'Organizer test','disabled','Organizer');DECLARE @O int=SCOPE_IDENTITY();
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('p-',@Suffix,'@test.invalid'),N'Participant test','disabled','Participant');DECLARE @P int=SCOPE_IDENTITY();
 INSERT dbo.Users(Email,Name,PasswordHash,Role)VALUES(CONCAT('j-',@Suffix,'@test.invalid'),N'Judge test','disabled','Judge');DECLARE @J int=SCOPE_IDENTITY();
 DECLARE @Created table(Id int);DECLARE @Open datetime2=DATEADD(day,-1,SYSUTCDATETIME()),@Close datetime2=DATEADD(day,1,SYSUTCDATETIME());
 INSERT @Created EXEC dbo.usp_CreateContest @O,N'Integration test',N'Film only',@Open,@Close,5,N'Landscape';
 DECLARE @C int=(SELECT Id FROM @Created);
 EXEC dbo.usp_Configure @O,@C,'award',N'First prize',0;
 EXEC dbo.usp_OpenContest @O,@C;
 EXEC dbo.usp_RegisterContest @P,@C;
 DECLARE @Stock int=(SELECT MIN(StockId) FROM dbo.FilmStocks);
 INSERT dbo.FilmRolls(UserId,Name,StockId,Stock,ISO,Camera,Lens,Format,Lab)VALUES(@P,'roll',@Stock,'Kodak Gold',200,'Nikon','50mm','35mm','Lab');DECLARE @Roll int=SCOPE_IDENTITY();
 DECLARE @Cat int=(SELECT CategoryId FROM dbo.Categories WHERE ContestId=@C);
 DECLARE @Submitted table(Id int);
 INSERT @Submitted EXEC dbo.usp_Submit @P,@C,@Cat,@Roll,1,N'Test frame',N'VN',N'2400dpi','negative-1','00000000000000000000000000000001.jpg','AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','0000000000000000',800,600;
 DECLARE @S int=(SELECT Id FROM @Submitted);

 EXEC dbo.usp_Review @O,@S,'Approved',N'Checked';
 UPDATE dbo.Contests SET Closes=DATEADD(minute,-2,SYSUTCDATETIME()),JudgingStart=DATEADD(minute,-1,SYSUTCDATETIME()),JudgingEnd=DATEADD(day,1,SYSUTCDATETIME()) WHERE ContestId=@C;
 EXEC dbo.usp_StartJudging @O,@C;
 DECLARE @Round int=(SELECT RoundId FROM dbo.JudgingRounds WHERE ContestId=@C);
 EXEC dbo.usp_Assign @O,@Round,@S,@J;
 DECLARE @A int=(SELECT AssignmentId FROM dbo.JudgeAssignments WHERE SubmissionId=@S);
 DECLARE @Criterion int=(SELECT MIN(CriterionId) FROM dbo.Criteria WHERE ContestId=@C);

 INSERT dbo.Scores(AssignmentId,CriterionId,Score,Comment) SELECT @A,CriterionId,8,N'Good' FROM dbo.Criteria WHERE ContestId=@C;
 UPDATE dbo.Contests SET JudgingEnd=DATEADD(second,-1,SYSUTCDATETIME()) WHERE ContestId=@C;
 EXEC dbo.usp_FinalizeScore @J,@A;
 THROW 52000,'FAIL: finalize after judging deadline accepted',1;
END TRY
BEGIN CATCH
 DECLARE @Error int=ERROR_NUMBER();
 IF @@TRANCOUNT>0 ROLLBACK;
 IF @Error NOT IN(51000) THROW;
 PRINT 'PASS: finalize after judging deadline rejected';
END CATCH;
GO
