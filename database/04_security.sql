USE FilmContest;
GO
-- Execute as dbo. Create the login separately with a unique strong password.
IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name='filmapp') CREATE USER filmapp FOR LOGIN filmapp;
IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name='film_runtime') CREATE ROLE film_runtime;
ALTER ROLE film_runtime ADD MEMBER filmapp;
-- Shared trusted application identity. End-user RBAC is checked by the server, not client SQL connections.
GRANT SELECT ON SCHEMA::dbo TO film_runtime;
GRANT EXECUTE ON SCHEMA::dbo TO film_runtime;
GRANT INSERT ON dbo.Users TO film_runtime;
GRANT UPDATE(Name,TokenVersion) ON dbo.Users TO film_runtime;
GRANT INSERT ON dbo.FilmRolls TO film_runtime;
DENY DELETE ON SCHEMA::dbo TO film_runtime;
GO
