$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '../src/FilmContest.Web')
dotnet restore
if ($LASTEXITCODE -ne 0) { throw 'Restore failed' }
dotnet build --no-restore
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
dotnet run --no-build
