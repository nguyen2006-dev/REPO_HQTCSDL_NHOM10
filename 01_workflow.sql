USE FilmContest;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;
BEGIN TRY
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
 EXEC dbo.usp_Review @O,@S,'Approved',N'Checked film evidence';
 -- DBA test fixture advances schedule; production application cannot update this directly.
 UPDATE dbo.Contests SET Closes=DATEADD(minute,-2,SYSUTCDATETIME()),JudgingStart=DATEADD(minute,-1,SYSUTCDATETIME()),JudgingEnd=DATEADD(day,1,SYSUTCDATETIME()) WHERE ContestId=@C;
 EXEC dbo.usp_StartJudging @O,@C;
 DECLARE @Round int=(SELECT RoundId FROM dbo.JudgingRounds WHERE ContestId=@C);
 EXEC dbo.usp_Assign @O,@Round,@S,@J;
 DECLARE @A int=(SELECT AssignmentId FROM dbo.JudgeAssignments WHERE SubmissionId=@S);
 DECLARE @Criterion int;DECLARE CriteriaCursor CURSOR LOCAL FAST_FORWARD FOR SELECT CriterionId FROM dbo.Criteria WHERE ContestId=@C;
 OPEN CriteriaCursor;FETCH NEXT FROM CriteriaCursor INTO @Criterion;
 WHILE @@FETCH_STATUS=0 BEGIN EXEC dbo.usp_Score @J,@A,@Criterion,8,N'Good';FETCH NEXT FROM CriteriaCursor INTO @Criterion;END;
 CLOSE CriteriaCursor;DEALLOCATE CriteriaCursor;
 EXEC dbo.usp_FinalizeScore @J,@A;
 EXEC dbo.usp_CloseRound @O,@Round;
 DECLARE @Award int=(SELECT AwardId FROM dbo.Awards WHERE ContestId=@C);
 EXEC dbo.usp_Award @O,@C,@Award,@S;
 EXEC dbo.usp_Publish @O,@C;
 IF NOT EXISTS(SELECT 1 FROM dbo.v_Rankings WHERE ContestId=@C AND TotalScore=8 AND Position=1)THROW 52000,'Incorrect weighted score',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.v_Archive WHERE SubmissionId=@S)THROW 52000,'Archive missing winner',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AuditLog WHERE EntityId=@S AND Action='ReviewSubmission')THROW 52000,'Review audit missing',1;
 ROLLBACK;PRINT 'PASS: complete workflow, weighted score, publication, archive, audit. Test data rolled back.';
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
GO
-- Negative authorization check. Expected business rejection, never an arbitrary SQL failure.
BEGIN TRY
 EXEC dbo.usp_RegisterContest -1,-1;
 THROW 52000,'FAIL: unauthorized registration accepted',1;
END TRY
BEGIN CATCH
 DECLARE @Error int=ERROR_NUMBER();
 IF @@TRANCOUNT>0 ROLLBACK;
 IF @Error<>51000 THROW;
 PRINT 'PASS: unauthorized registration rejected';
END CATCH;
GO
BEGIN TRY
 EXEC dbo.usp_Score -1,-1,-1,11,N'Invalid';
 THROW 52000,'FAIL: invalid scoring accepted',1;
END TRY
BEGIN CATCH
 DECLARE @Error int=ERROR_NUMBER();
 IF @@TRANCOUNT>0 ROLLBACK;
 IF @Error<>51000 THROW;
 PRINT 'PASS: unassigned judge rejected';
END CATCH;
GO
