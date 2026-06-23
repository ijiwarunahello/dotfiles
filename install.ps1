#Requires -Version 5.1
# Windows (native PowerShell) counterpart of install.sh.
# Deploys dotfiles into $HOME via symlinks (GNU Stow equivalent) and wires up
# the PowerShell profile. Symlink creation needs Developer Mode (or admin).
# Set $env:DRY_RUN = '1' to print actions only.

$ErrorActionPreference = 'Stop'
$DryRun = ($env:DRY_RUN -eq '1')
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- low-level steps (dry-run aware) -----------------------------------------
function Step-Mkdir {
  param([Parameter(Mandatory)][string]$Path)
  if (Test-Path -LiteralPath $Path) { return }
  if ($DryRun) { Write-Host "[dry-run] mkdir $Path" -ForegroundColor Cyan; return }
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Step-Remove {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return }
  if ($DryRun) { Write-Host "[dry-run] remove $Path" -ForegroundColor Cyan; return }
  Remove-Item -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue
}

function Step-Backup {
  param([Parameter(Mandatory)][string]$Path)
  $bak = "$Path.bak"
  if (Test-Path -LiteralPath $bak) {
    $bak = "$Path.$(Get-Date -Format 'yyyyMMddHHmmss').bak"
  }
  if ($DryRun) { Write-Host "[dry-run] backup $Path -> $bak" -ForegroundColor Cyan; return }
  Move-Item -LiteralPath $Path -Destination $bak -Force
  Write-Host "backed up $Path -> $bak" -ForegroundColor Yellow
}

function Step-Symlink {
  param(
    [Parameter(Mandatory)][string]$Link,
    [Parameter(Mandatory)][string]$Target
  )
  if (Test-Path -LiteralPath $Link) {
    $existing = Get-Item -LiteralPath $Link -Force
    if ($existing.LinkType -eq 'SymbolicLink') {
      Step-Remove $Link
    } else {
      Step-Backup $Link
    }
  }

  $parent = Split-Path -Parent $Link
  if ($parent -and -not (Test-Path -LiteralPath $parent)) { Step-Mkdir $parent }

  if ($DryRun) { Write-Host "[dry-run] symlink $Link -> $Target" -ForegroundColor Cyan; return }

  try {
    New-Item -ItemType SymbolicLink -Path $Link -Target $Target -Force -ErrorAction Stop | Out-Null
  } catch {
    Write-Host "failed to create symlink: $Link -> $Target" -ForegroundColor Red
    Write-Host 'enable Developer Mode (Settings > Privacy & security > For developers) or run as admin, then re-run.' -ForegroundColor Red
    throw
  }
  Write-Host "linked $Link -> $Target" -ForegroundColor Green
}

# --- symlink resolution ------------------------------------------------------
# A repo entry can be:
#   1. a real symlink (core.symlinks=true checkout)
#   2. a git symlink materialized as a small text file holding a relative path
#      (core.symlinks=false checkout — e.g. agents vendored skills)
#   3. a normal file
# Returns the ultimate real target to point a deployed symlink at.
function Resolve-LinkTarget {
  param([Parameter(Mandatory)][string]$Path)
  $item = Get-Item -LiteralPath $Path -Force

  if ($item.LinkType -eq 'SymbolicLink') {
    $target = $item.Target
    if ($target -is [array]) { $target = $target[0] }
    if (-not [IO.Path]::IsPathRooted($target)) {
      $target = Join-Path (Split-Path -Parent $Path) $target
    }
    try { return (Resolve-Path -LiteralPath $target -ErrorAction Stop).Path } catch { return $target }
  }

  if (Test-TextSymlink -Path $Path) {
    $content = (Get-Content -LiteralPath $Path -Raw).Trim()
    $candidate = Join-Path (Split-Path -Parent $Path) $content
    return (Resolve-Path -LiteralPath $candidate).Path
  }

  return $item.FullName
}

# True when $Path is a git-symlink-as-text-file: a small single-line file whose
# content is a relative path (contains a separator) that resolves to a real path.
function Test-TextSymlink {
  param([Parameter(Mandatory)][string]$Path)
  $item = Get-Item -LiteralPath $Path -Force
  if ($item.PSIsContainer) { return $false }
  if ($item.LinkType -eq 'SymbolicLink') { return $false }
  if ($item.Length -gt 1024) { return $false }

  $content = (Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue)
  if (-not $content) { return $false }
  $content = $content.Trim()
  if ($content -match "[`r`n]") { return $false }
  if ($content -notmatch '[/\\]') { return $false }

  $candidate = Join-Path (Split-Path -Parent $Path) $content
  return (Test-Path -LiteralPath $candidate)
}

# --- stow-like deploy --------------------------------------------------------
# Mirror $SrcDir's children into $DestDir: plain directories become real
# directories (so runtime data can coexist), files and links become symlinks.
function Install-Tree {
  param(
    [Parameter(Mandatory)][string]$SrcDir,
    [Parameter(Mandatory)][string]$DestDir
  )
  if (-not (Test-Path -LiteralPath $DestDir)) { Step-Mkdir $DestDir }

  foreach ($child in (Get-ChildItem -LiteralPath $SrcDir -Force)) {
    $dest   = Join-Path $DestDir $child.Name
    $isLink = ($child.LinkType -eq 'SymbolicLink') -or (Test-TextSymlink -Path $child.FullName)

    if ($child.PSIsContainer -and -not $isLink) {
      Install-Tree -SrcDir $child.FullName -DestDir $dest
    } else {
      Step-Symlink -Link $dest -Target (Resolve-LinkTarget -Path $child.FullName)
    }
  }
}

function Install-Package {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Target
  )
  Write-Host "stow $Name -> $Target" -ForegroundColor Yellow
  Install-Tree -SrcDir (Join-Path $Root $Name) -DestDir $Target
}

# Remove deployed symlinks under $Dir so orphaned links are cleaned (stow -R).
function Clear-SymlinkChildren {
  param([Parameter(Mandatory)][string]$Dir)
  if (-not (Test-Path -LiteralPath $Dir)) { return }
  foreach ($child in (Get-ChildItem -LiteralPath $Dir -Force)) {
    if ($child.LinkType -eq 'SymbolicLink') { Step-Remove $child.FullName }
  }
}

# --- run ---------------------------------------------------------------------
& (Join-Path $Root 'setup\install-libraries.ps1')

Step-Mkdir (Join-Path $HOME '.agents\skills')

foreach ($pkg in @('claude', 'codex', 'workspace-inbox')) {
  Install-Package -Name $pkg -Target $HOME
}

# agents: restow so deleted skill links get cleaned up first
Clear-SymlinkChildren (Join-Path $HOME '.agents\skills')
Install-Package -Name 'agents' -Target $HOME

# PowerShell profile (linked explicitly; its path is outside the $HOME tree)
$profileSrc  = Join-Path $Root 'powershell\Microsoft.PowerShell_profile.ps1'
$profileDest = $PROFILE.CurrentUserAllHosts
Step-Symlink -Link $profileDest -Target $profileSrc

Write-Host 'all setting done.' -ForegroundColor Yellow
Write-Host "next: open a new PowerShell session to load the profile ($profileDest)." -ForegroundColor Yellow
Write-Host "next: run 'gh auth login' and then 'gh auth setup-git' when GitHub authentication is needed." -ForegroundColor Yellow
Write-Host "note: worktrunk's CLI is 'git-wt' on Windows (plain 'wt' is Windows Terminal); the profile auto-enables its directory switching on load." -ForegroundColor Yellow
