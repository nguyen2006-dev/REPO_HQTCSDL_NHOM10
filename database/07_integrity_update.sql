-- Run for existing databases after 02_procedures.sql and 03_management.sql.
-- No data deletion. Stop if old data violates the constraint; correct that data first.
USE FilmContest;
GO
SET XACT_ABORT ON;
BEGIN TRAN;
ALTER TABLE dbo.Contests DROP CONSTRAINT CK_JudgingDates;
ALTER TABLE dbo.Contests WITH CHECK ADD CONSTRAINT CK_JudgingDates CHECK((JudgingStart IS NULL AND JudgingEnd IS NULL) OR (JudgingStart IS NOT NULL AND JudgingEnd IS NOT NULL AND JudgingStart>Closes AND JudgingEnd>JudgingStart));
COMMIT;
GO
