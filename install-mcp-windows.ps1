# install-mcp-windows.ps1
# Deploys MCP server configurations from this dotfiles repo to the current Windows system.
# Targets: ~/.copilot/mcp-config.json, ~/.mcp.json, ~/.claude/settings.json, ~/.codex/config.toml
# Performs sandriaas → current username replacement (same as install.sh on Linux).

param(
    [switch]$DryRun,
    [switch]$Force,
    [string]$RepoUrl = "https://github.com/sandriaas/_dotfiles"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# If running from a cloned repo, use local files. Otherwise, download from GitHub.
$RepoRoot = $PSScriptRoot
$LocalDir = Join-Path $RepoRoot "local"

# Check if we have local files, if not download from GitHub
if (-not (Test-Path $LocalDir)) {
    Write-Host "[INFO] Local files not found. Cloning from GitHub..." -ForegroundColor Yellow
    $TempRepo = Join-Path $env:TEMP "dotfiles-install-$(Get-Random)"
    git clone --depth 1 $RepoUrl $TempRepo 2>&1 | Out-Null
    if (-not $?) {
        Write-Host "[ERROR] Failed to clone repository. Please ensure git is installed." -ForegroundColor Red
        exit 1
    }
    $RepoRoot = $TempRepo
    $LocalDir = Join-Path $TempRepo "local"
}
$Username = $env:USERNAME
$UserHome = $env:USERPROFILE

Write-Host "`n=== MCP Config Installer for Windows ===" -ForegroundColor Cyan
Write-Host "Repo:     $RepoRoot"
Write-Host "Username: $Username"
Write-Host "Home:     $UserHome"
if ($DryRun) { Write-Host "[DRY RUN] No files will be written." -ForegroundColor Yellow }
Write-Host ""

# Source → Destination mapping (relative to local/ → relative to ~/)
$ConfigFiles = @(
    @{ Src = ".copilot\mcp-config.json"; Dst = ".copilot\mcp-config.json" }
    @{ Src = ".mcp.json";                Dst = ".mcp.json" }
    @{ Src = ".claude\settings.json";    Dst = ".claude\settings.json" }
    @{ Src = ".codex\config.toml";       Dst = ".codex\config.toml" }
)

$Deployed = 0
$Skipped = 0
$Backed = 0

foreach ($cfg in $ConfigFiles) {
    $srcPath = Join-Path $LocalDir $cfg.Src
    $dstPath = Join-Path $UserHome $cfg.Dst

    Write-Host "--- $($cfg.Dst) ---" -ForegroundColor White

    if (-not (Test-Path $srcPath)) {
        Write-Host "  [SKIP] Source not found: $srcPath" -ForegroundColor DarkYellow
        $Skipped++
        continue
    }

    # Read source and replace template username with current username
    $content = Get-Content $srcPath -Raw
    if ($Username -ne "sandriaas") {
        $content = $content -replace "sandriaas", $Username
        # Also fix Linux home paths → Windows home paths
        $content = $content -replace "/home/$Username", ($UserHome -replace "\\", "/")
    }

    # Backup existing file
    if (Test-Path $dstPath) {
        if (-not $Force) {
            Write-Host "  [EXISTS] $dstPath" -ForegroundColor DarkYellow
            Write-Host "  Use -Force to overwrite (backup will be created)." -ForegroundColor DarkYellow
            $Skipped++
            continue
        }
        $backupPath = "$dstPath.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        if (-not $DryRun) {
            Copy-Item $dstPath $backupPath
        }
        Write-Host "  [BACKUP] $backupPath" -ForegroundColor DarkGray
        $Backed++
    }

    # Ensure parent directory exists
    $dstDir = Split-Path $dstPath -Parent
    if (-not (Test-Path $dstDir)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }
        Write-Host "  [MKDIR] $dstDir" -ForegroundColor DarkGray
    }

    # Write file
    if (-not $DryRun) {
        Set-Content -Path $dstPath -Value $content -NoNewline -Encoding UTF8
    }
    Write-Host "  [OK] Deployed to $dstPath" -ForegroundColor Green
    $Deployed++
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Deployed: $Deployed  |  Skipped: $Skipped  |  Backups: $Backed"
if ($DryRun) { Write-Host "(Dry run — nothing was written)" -ForegroundColor Yellow }

# Cleanup temp repo if we cloned it
if ($RepoRoot -like "*\Temp\dotfiles-install-*") {
    Remove-Item -Recurse -Force $RepoRoot -ErrorAction SilentlyContinue
    Write-Host "[CLEANUP] Removed temporary clone" -ForegroundColor DarkGray
}

Write-Host ""
