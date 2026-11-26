param(
    [string]$Server = 'localhost\SQLEXPRESS',
    [switch]$Update
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { throw 'Install .NET 8 SDK before continuing.' }
function Invoke-Dotnet {
    param([string[]]$Arguments)
    & dotnet @Arguments
    if ($LASTEXITCODE -ne 0) { throw "dotnet command failed ($LASTEXITCODE). Read the error above." }
}
$env:FILM_DB_ADMIN = "Server=$Server;Database=master;Integrated Security=True;Encrypt=True;TrustServerCertificate=True"
if ($Update) {
    Invoke-Dotnet -Arguments @('run','--project','scripts/FilmContest.DbTool','--','update','.')
} else {
    $appSecret = Read-Host 'New SQL filmapp password (16-128 chars, SQL Mixed Mode required)' -AsSecureString
    $appPassword = [System.Net.NetworkCredential]::new('', $appSecret).Password
    $env:FILM_APP_PASSWORD = $appPassword
    try { Invoke-Dotnet -Arguments @('run','--project','scripts/FilmContest.DbTool','--','init','.') }
    finally { Remove-Item Env:FILM_APP_PASSWORD -ErrorAction SilentlyContinue }
    $project = 'src/FilmContest.Web'
    # A connection-string builder handles semicolons and quotes inside passwords.
    $builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
    $builder.DataSource = $Server
    $builder.InitialCatalog = 'FilmContest'
    $builder.UserID = 'filmapp'
    $builder.Password = $appPassword
    $builder.Encrypt = $true
    $builder.TrustServerCertificate = $true
    Invoke-Dotnet -Arguments @('user-secrets','set','--project',$project,'ConnectionStrings:SqlServer',$builder.ConnectionString)
    $bytes = New-Object byte[] 48
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    Invoke-Dotnet -Arguments @('user-secrets','set','--project',$project,'Jwt:Key',[Convert]::ToBase64String($bytes))
    $email = Read-Host 'First administrator email'
    $adminSecret = Read-Host 'First administrator password (at least 12 chars)' -AsSecureString
    $adminPassword = [System.Net.NetworkCredential]::new('', $adminSecret).Password
    if ($adminPassword.Length -lt 12 -or $email -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$') { throw 'Invalid admin email/password; configure Bootstrap user-secrets as shown in README.' }
    Invoke-Dotnet -Arguments @('user-secrets','set','--project',$project,'Bootstrap:AdminEmail',$email)
    Invoke-Dotnet -Arguments @('user-secrets','set','--project',$project,'Bootstrap:AdminPassword',$adminPassword)
}
Invoke-Dotnet -Arguments @('build','FilmContest.sln')
Invoke-Dotnet -Arguments @('run','--project','tests/FilmContest.Checks','--','.')
Write-Host 'Next: dotnet dev-certs https --trust'
Write-Host 'Run:  .\scripts\run.ps1'
Write-Host 'After first admin login, remove Bootstrap:AdminEmail and Bootstrap:AdminPassword user-secrets.'
