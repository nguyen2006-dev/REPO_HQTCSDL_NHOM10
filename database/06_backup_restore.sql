-- Run as DBA; edit filesystem paths on the SQL SERVER host, not the browser machine.
-- First full backup (do not overwrite the only existing copy).
BACKUP DATABASE FilmContest TO DISK=N'/var/opt/mssql/backup/FilmContest_full.bak' WITH CHECKSUM,COMPRESSION,STATS=10;
RESTORE VERIFYONLY FROM DISK=N'/var/opt/mssql/backup/FilmContest_full.bak' WITH CHECKSUM;
-- Restore into a separate validation DB, using paths valid for your SQL instance:
-- RESTORE FILELISTONLY FROM DISK=N'/var/opt/mssql/backup/FilmContest_full.bak';
-- RESTORE DATABASE FilmContest_RestoreCheck FROM DISK=N'/var/opt/mssql/backup/FilmContest_full.bak'
-- WITH MOVE 'FilmContest' TO '/var/opt/mssql/data/FilmContest_RestoreCheck.mdf',
-- MOVE 'FilmContest_log' TO '/var/opt/mssql/data/FilmContest_RestoreCheck_log.ldf';
-- DBCC CHECKDB(FilmContest_RestoreCheck) WITH NO_INFOMSGS;
-- Back up assets/private blob containers as well; database backups do not contain image files.
