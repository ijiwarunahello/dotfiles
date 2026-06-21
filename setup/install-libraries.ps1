#Requires -Version 5.1
# Windows (native PowerShell) counterpart of setup/install-libraries.sh.
# Installs CLI tools via scoop. Set $env:DRY_RUN = '1' to print actions only.

$ErrorActionPreference = 'Stop'
$DryRun = ($env:DRY_RUN -eq '1')

function Invoke-Step {
  param(
    [Parameter(Mandatory)][string]$Display,
    [Parameter(Mandatory)][scriptblock]$Action
  )
  if ($DryRun) {
    Write-Host "[dry-run] $Display" -ForegroundColor Cyan
  } else {
    & $Action
  }
}

Write-Host 'install libraries for Windows (scoop)...' -ForegroundColor Yellow

# --- scoop --------------------------------------------------------------------
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
  Write-Host 'scoop not found; installing...' -ForegroundColor Yellow
  Invoke-Step -Display 'Set-ExecutionPolicy -Scope CurrentUser RemoteSigned' -Action {
    Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
  }
  Invoke-Step -Display 'irm get.scoop.sh | iex' -Action {
    Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression
  }
  # make scoop available in the current session right after install
  $scoopShims = Join-Path $HOME 'scoop\shims'
  if ((Test-Path -LiteralPath $scoopShims) -and ($env:PATH -notlike "*$scoopShims*")) {
    $env:PATH = "$scoopShims;$env:PATH"
  }
}

# --- tools (all in scoop's default `main` bucket) -----------------------------
# worktrunk installs its CLI as `git-wt` on Windows (plain `wt` is Windows Terminal).
$tools = @('starship', 'zoxide', 'gh', 'fzf', 'ghq', 'git', 'vim', 'worktrunk')
Invoke-Step -Display "scoop install $($tools -join ' ')" -Action {
  scoop install @tools
}

if (-not $DryRun -and -not (Get-Command git-wt -CommandType Application -ErrorAction SilentlyContinue)) {
  Write-Host 'worktrunk (git-wt) not found after install; `gw` / `gwc` will be unavailable.' -ForegroundColor Yellow
}
