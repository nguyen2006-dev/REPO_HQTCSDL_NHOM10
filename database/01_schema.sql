-- SQL Server 2022+. Run in SSMS with a database-owner account.
USE master;
GO
IF DB_ID(N'FilmContest') IS NULL CREATE DATABASE FilmContest;
GO
USE FilmContest;
GO
CREATE TABLE dbo.PlatformSettings(SettingKey varchar(40) PRIMARY KEY,SettingValue nvarchar(1000) NOT NULL);
INSERT dbo.PlatformSettings VALUES('Banner',N''),('RequireNegative','0');
CREATE TABLE dbo.Users(
 UserId int IDENTITY PRIMARY KEY,Email nvarchar(254) NOT NULL UNIQUE,Name nvarchar(120) NOT NULL,
 PasswordHash nvarchar(500) NOT NULL,Role varchar(20) NOT NULL DEFAULT 'Participant' CHECK(Role IN('Admin','Organizer','Judge','Participant')),
 Active bit NOT NULL DEFAULT 1,TokenVersion int NOT NULL DEFAULT 1,CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
CREATE TABLE dbo.Contests(
 ContestId int IDENTITY PRIMARY KEY,OwnerId int NOT NULL REFERENCES dbo.Users(UserId),Title nvarchar(180) NOT NULL,
 Rules nvarchar(4000) NOT NULL,Opens datetime2 NOT NULL,Closes datetime2 NOT NULL,
 MaxEntries int NOT NULL CHECK(MaxEntries BETWEEN 1 AND 100),Status varchar(20) NOT NULL DEFAULT 'Draft' CHECK(Status IN('Draft','Open','Judging','Published')),
 JudgingStart datetime2 NULL,JudgingEnd datetime2 NULL,
 CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),CONSTRAINT CK_Dates CHECK(Opens<Closes),CONSTRAINT CK_JudgingDates CHECK(JudgingStart IS NULL OR (JudgingStart>Closes AND JudgingEnd>JudgingStart)));
CREATE TABLE dbo.Categories(CategoryId int IDENTITY PRIMARY KEY,ContestId int NOT NULL REFERENCES dbo.Contests(ContestId),Name nvarchar(120) NOT NULL,
 UNIQUE(ContestId,Name),UNIQUE(ContestId,CategoryId));
CREATE TABLE dbo.Registrations(ContestId int NOT NULL REFERENCES dbo.Contests(ContestId),UserId int NOT NULL REFERENCES dbo.Users(UserId),RegisteredAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),PRIMARY KEY(ContestId,UserId));
CREATE TABLE dbo.FilmStocks(StockId int IDENTITY PRIMARY KEY,Brand nvarchar(80) NOT NULL,Name nvarchar(100) NOT NULL,DefaultISO int NOT NULL CHECK(DefaultISO BETWEEN 1 AND 102400),Active bit NOT NULL DEFAULT 1,UNIQUE(Brand,Name));
INSERT dbo.FilmStocks(Brand,Name,DefaultISO)VALUES('Kodak','Gold 200',200),('Kodak','Portra 400',400),('Ilford','HP5 Plus',400),('Fujifilm','Fujicolor 200',200);
CREATE TABLE dbo.FilmRolls(RollId int IDENTITY PRIMARY KEY,UserId int NOT NULL REFERENCES dbo.Users(UserId),Name nvarchar(100) NOT NULL,StockId int NOT NULL REFERENCES dbo.FilmStocks(StockId),Stock nvarchar(100) NOT NULL,
 ISO int NOT NULL CHECK(ISO BETWEEN 1 AND 102400),Camera nvarchar(100) NOT NULL,Lens nvarchar(100) NOT NULL,Format nvarchar(40) NOT NULL,Lab nvarchar(180) NOT NULL,
 UNIQUE(UserId,Name),UNIQUE(UserId,RollId));
CREATE TABLE dbo.Frames(FrameId int IDENTITY PRIMARY KEY,RollId int NOT NULL REFERENCES dbo.FilmRolls(RollId),FrameNumber int NOT NULL CHECK(FrameNumber BETWEEN 1 AND 1000),
 Location nvarchar(300) NOT NULL,ScanSpecs nvarchar(1000) NOT NULL,NegativeReference nvarchar(500) NOT NULL,UNIQUE(RollId,FrameNumber));
CREATE TABLE dbo.Submissions(SubmissionId int IDENTITY PRIMARY KEY,ContestId int NOT NULL,CategoryId int NOT NULL,UserId int NOT NULL,FrameId int NOT NULL REFERENCES dbo.Frames(FrameId),
 Title nvarchar(180) NOT NULL,AssetKey varchar(40) NOT NULL,Sha256 char(64) NOT NULL,PHash char(16) NOT NULL,Width int NOT NULL,Height int NOT NULL,
 Status varchar(20) NOT NULL DEFAULT 'Pending' CHECK(Status IN('Pending','Approved','Rejected')),SubmittedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
 FOREIGN KEY(ContestId,CategoryId) REFERENCES dbo.Categories(ContestId,CategoryId),FOREIGN KEY(ContestId,UserId) REFERENCES dbo.Registrations(ContestId,UserId),
 UNIQUE(ContestId,FrameId),UNIQUE(ContestId,Sha256));
CREATE TABLE dbo.SubmissionReviews(ReviewId int IDENTITY PRIMARY KEY,SubmissionId int NOT NULL REFERENCES dbo.Submissions(SubmissionId),ReviewerId int NOT NULL REFERENCES dbo.Users(UserId),Decision varchar(20) NOT NULL CHECK(Decision IN('Approved','Rejected')),Reason nvarchar(1000) NOT NULL,ReviewedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
CREATE TABLE dbo.Criteria(CriterionId int IDENTITY PRIMARY KEY,ContestId int NOT NULL REFERENCES dbo.Contests(ContestId),Name nvarchar(100) NOT NULL,Weight decimal(5,4) NOT NULL CHECK(Weight>0 AND Weight<=1),UNIQUE(ContestId,Name));
CREATE TABLE dbo.JudgingRounds(RoundId int IDENTITY PRIMARY KEY,ContestId int NOT NULL REFERENCES dbo.Contests(ContestId),Name nvarchar(100) NOT NULL,RoundNumber int NOT NULL CHECK(RoundNumber>0),State varchar(10) NOT NULL DEFAULT 'Draft' CHECK(State IN('Draft','Open','Closed')),UNIQUE(ContestId,RoundNumber));
CREATE TABLE dbo.JudgeAssignments(AssignmentId int IDENTITY PRIMARY KEY,RoundId int NOT NULL REFERENCES dbo.JudgingRounds(RoundId),SubmissionId int NOT NULL REFERENCES dbo.Submissions(SubmissionId),JudgeId int NOT NULL REFERENCES dbo.Users(UserId),Finalized bit NOT NULL DEFAULT 0,UNIQUE(RoundId,SubmissionId,JudgeId));
CREATE TABLE dbo.Scores(AssignmentId int NOT NULL REFERENCES dbo.JudgeAssignments(AssignmentId),CriterionId int NOT NULL REFERENCES dbo.Criteria(CriterionId),Score decimal(4,2) NOT NULL CHECK(Score BETWEEN 0 AND 10),Comment nvarchar(1000) NOT NULL,UpdatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),PRIMARY KEY(AssignmentId,CriterionId));
CREATE TABLE dbo.Awards(AwardId int IDENTITY PRIMARY KEY,ContestId int NOT NULL REFERENCES dbo.Contests(ContestId),Name nvarchar(120) NOT NULL,Prize nvarchar(300) NOT NULL,UNIQUE(ContestId,Name));
CREATE TABLE dbo.SubmissionAwards(AwardId int NOT NULL REFERENCES dbo.Awards(AwardId),SubmissionId int NOT NULL REFERENCES dbo.Submissions(SubmissionId),PRIMARY KEY(AwardId,SubmissionId));
CREATE TABLE dbo.AICheckResults(CheckId int IDENTITY PRIMARY KEY,SubmissionId int NOT NULL REFERENCES dbo.Submissions(SubmissionId),Kind varchar(30) NOT NULL CHECK(Kind IN('Similarity','GeneratedImage','Tags')),Status varchar(20) NOT NULL CHECK(Status IN('Clear','Flagged','Unavailable')),Score decimal(6,5) NULL CHECK(Score BETWEEN 0 AND 1),Detail nvarchar(2000) NOT NULL,ModelVersion nvarchar(120) NOT NULL,CheckedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),UNIQUE(SubmissionId,Kind));
CREATE TABLE dbo.AuditLog(AuditId bigint IDENTITY PRIMARY KEY,ActorId int NULL REFERENCES dbo.Users(UserId),Action nvarchar(80) NOT NULL,EntityId int NOT NULL,Detail nvarchar(1000) NOT NULL,OccurredAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
CREATE INDEX IX_Submission_Queue ON dbo.Submissions(ContestId,Status) INCLUDE(UserId,CategoryId,SubmittedAt);
CREATE INDEX IX_Assignment_Judge ON dbo.JudgeAssignments(JudgeId,Finalized) INCLUDE(RoundId,SubmissionId);
CREATE INDEX IX_Submission_Hash ON dbo.Submissions(Sha256);
GO
CREATE VIEW dbo.v_RoundScores AS
SELECT a.RoundId,a.SubmissionId,a.AssignmentId,a.JudgeId,a.Finalized,SUM(s.Score*c.Weight) AS WeightedScore,
 COUNT(s.CriterionId) AS ScoredCriteria
FROM dbo.JudgeAssignments a LEFT JOIN dbo.Scores s ON s.AssignmentId=a.AssignmentId
LEFT JOIN dbo.Criteria c ON c.CriterionId=s.CriterionId
GROUP BY a.RoundId,a.SubmissionId,a.AssignmentId,a.JudgeId,a.Finalized;
GO
-- Final ranking uses the highest-numbered round, averaged over finalized judges.
-- RANK preserves ties. Organizer assigns awards explicitly, including tied entries.
CREATE VIEW dbo.v_Rankings AS
WITH FinalRound AS(SELECT RoundId,ContestId FROM dbo.JudgingRounds r WHERE RoundNumber=(SELECT MAX(r2.RoundNumber) FROM dbo.JudgingRounds r2 WHERE r2.ContestId=r.ContestId)),
Totals AS(SELECT r.ContestId,s.SubmissionId,CAST(AVG(v.WeightedScore) AS decimal(8,4)) AS TotalScore
FROM FinalRound r JOIN dbo.v_RoundScores v ON v.RoundId=r.RoundId AND v.Finalized=1 JOIN dbo.Submissions s ON s.SubmissionId=v.SubmissionId
GROUP BY r.ContestId,s.SubmissionId)
SELECT t.*,s.Title,s.CategoryId,u.Name AS Photographer,RANK() OVER(PARTITION BY t.ContestId,s.CategoryId ORDER BY t.TotalScore DESC) AS Position
FROM Totals t JOIN dbo.Submissions s ON s.SubmissionId=t.SubmissionId JOIN dbo.Users u ON u.UserId=s.UserId;
GO
CREATE VIEW dbo.v_Archive AS SELECT c.ContestId,c.Title AS ContestTitle,s.SubmissionId,s.Title,u.Name AS Photographer,
 r.Stock,r.Camera,r.Lens,r.ISO,r.Format,r.Lab,f.FrameNumber,f.Location,f.ScanSpecs,a.Name AS Award,a.Prize
FROM dbo.SubmissionAwards sa JOIN dbo.Awards a ON a.AwardId=sa.AwardId JOIN dbo.Submissions s ON s.SubmissionId=sa.SubmissionId
JOIN dbo.Contests c ON c.ContestId=s.ContestId JOIN dbo.Users u ON u.UserId=s.UserId JOIN dbo.Frames f ON f.FrameId=s.FrameId JOIN dbo.FilmRolls r ON r.RollId=f.RollId WHERE c.Status='Published';
GO
CREATE OR ALTER TRIGGER dbo.tr_ReviewAudit ON dbo.SubmissionReviews AFTER INSERT AS
INSERT dbo.AuditLog(ActorId,Action,EntityId,Detail) SELECT ReviewerId,'ReviewSubmission',SubmissionId,CONCAT(Decision,': ',Reason) FROM inserted;
GO
