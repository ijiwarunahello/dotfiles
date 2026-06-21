# PowerShell profile — Windows port of zsh/.zsh/.zshrc
# Mirrors the aliases, workspace/agent helpers, and tool init (zoxide/starship/wt).

# --- PATH ---------------------------------------------------------------------
$localBin = Join-Path $HOME '.local\bin'
if ($env:PATH -notlike "*$localBin*") {
  $env:PATH = "$localBin;$env:PATH"
}

# --- history (PSReadLine equivalent of share_history / HISTSIZE) ---------------
if (Get-Module -ListAvailable -Name PSReadLine) {
  Import-Module PSReadLine -ErrorAction SilentlyContinue
  Set-PSReadLineOption -HistorySaveStyle SaveIncrementally -MaximumHistoryCount 10000 -ErrorAction SilentlyContinue
}

# --- aliases ------------------------------------------------------------------
function l  { Get-ChildItem @args | Sort-Object LastWriteTime }   # ls -ltr
function ll { Get-ChildItem @args }                                # ls -l
function la { Get-ChildItem -Force @args }                         # ls -la
function .. { Set-Location .. }
Set-Alias -Name v  -Value vim -ErrorAction SilentlyContinue
Set-Alias -Name vi -Value vim -ErrorAction SilentlyContinue

# --- internal helpers ---------------------------------------------------------
function _dotfiles_warn { param([string]$Message) [Console]::Error.WriteLine($Message) }

function _dotfiles_require {
  param([Parameter(Mandatory)][string]$Name)
  if (Get-Command $Name -ErrorAction SilentlyContinue) { return $true }
  _dotfiles_warn "$Name is required."
  return $false
}

function _dotfiles_workspace_root {
  if ($env:WORKSPACES_SRC) { return $env:WORKSPACES_SRC }
  return (Join-Path $HOME 'Workspaces\src')
}

function _dotfiles_agent_inbox_repo {
  if ($env:AGENT_INBOX_REPO) { return $env:AGENT_INBOX_REPO }
  return (Join-Path (_dotfiles_workspace_root) 'github.com\ijiwarunahello\workspace-inbox')
}

function _dotfiles_agent_cwd_allowed {
  $root = _dotfiles_workspace_root
  try { $root = (Resolve-Path -LiteralPath $root -ErrorAction Stop).Path } catch { }
  $cwd = (Get-Location).ProviderPath

  $sep   = [IO.Path]::DirectorySeparatorChar
  $rootN = $root.TrimEnd('\', '/')
  $cwdN  = $cwd.TrimEnd('\', '/')

  if ($cwdN -eq $rootN -or
      $cwdN.StartsWith($rootN + $sep, [StringComparison]::OrdinalIgnoreCase)) {
    return $true
  }

  _dotfiles_warn "agent cwd is outside trusted workspace root: $cwd"
  _dotfiles_warn "trusted workspace root: $root"
  return $false
}

function _dotfiles_run_agent {
  $rest = @($args)
  if ($rest.Count -eq 0) {
    _dotfiles_warn 'usage: _dotfiles_run_agent <codex|claude|app|codex-app> [args...]'
    return
  }

  $agent = $rest[0]
  $rest  = if ($rest.Count -gt 1) { $rest[1..($rest.Count - 1)] } else { @() }

  if ($agent -notin @('codex', 'claude', 'app', 'codex-app')) {
    _dotfiles_warn 'usage: _dotfiles_run_agent <codex|claude|app|codex-app> [args...]'
    return
  }

  $tool = if ($agent -in @('app', 'codex-app')) { 'codex' } else { $agent }
  if (-not (_dotfiles_require $tool)) { return }
  if (-not (_dotfiles_agent_cwd_allowed)) { return }

  if ($agent -in @('app', 'codex-app')) {
    & codex app @rest
  } else {
    & $agent @rest
  }
}

# Resolve worktrunk's CLI. scoop installs it as `git-wt` (plain `wt` is Windows
# Terminal). Prefer `git-wt`; otherwise fall back to a `wt` that is NOT Windows
# Terminal. Override with $env:WORKTRUNK_BIN if auto-detection picks wrong.
function _dotfiles_worktrunk {
  if ($env:WORKTRUNK_BIN) { return $env:WORKTRUNK_BIN }

  $gw = Get-Command git-wt -CommandType Application -ErrorAction SilentlyContinue
  if ($gw) { return $gw.Source }

  $cmds = @(Get-Command wt -CommandType Application -All -ErrorAction SilentlyContinue)
  foreach ($c in $cmds) {
    if ($c.Source -and $c.Source -notmatch 'WindowsApps' -and $c.Source -notmatch 'WindowsTerminal') {
      return $c.Source
    }
  }
  return $null
}

function _dotfiles_pick_repo {
  if (-not (_dotfiles_require ghq)) { return }
  if (-not (_dotfiles_require fzf)) { return }

  $repo = ghq list -p | fzf --prompt='repo> '
  if ($LASTEXITCODE -ne 0) { return }
  if ([string]::IsNullOrWhiteSpace($repo)) { return }
  return $repo.Trim()
}

# --- workspace / agent commands ----------------------------------------------
function g {
  $repo = _dotfiles_pick_repo
  if ($repo) { Set-Location -LiteralPath $repo }
}

function c  { _dotfiles_run_agent codex @args }
function cx { _dotfiles_run_agent codex @args }
function ca { _dotfiles_run_agent app @args }
function cl { _dotfiles_run_agent claude @args }

function ai {
  $rest  = @($args)
  $agent = 'claude'
  if ($rest.Count -ge 1 -and $rest[0] -in @('codex', 'claude', 'app', 'codex-app')) {
    $agent = $rest[0]
    $rest  = if ($rest.Count -gt 1) { $rest[1..($rest.Count - 1)] } else { @() }
  }

  $repo = _dotfiles_pick_repo
  if (-not $repo) { return }
  try { Set-Location -LiteralPath $repo -ErrorAction Stop } catch { return }
  _dotfiles_run_agent $agent @rest
}

function aip {
  $rest  = @($args)
  $agent = 'claude'
  if ($rest.Count -ge 1 -and $rest[0] -in @('codex', 'claude', 'app', 'codex-app')) {
    $agent = $rest[0]
    $rest  = if ($rest.Count -gt 1) { $rest[1..($rest.Count - 1)] } else { @() }
  }

  $repo = _dotfiles_agent_inbox_repo
  if (-not (Test-Path -LiteralPath $repo -PathType Container)) {
    _dotfiles_warn "agent inbox repo does not exist: $repo"
    _dotfiles_warn 'create it under ~/Workspaces/src or set AGENT_INBOX_REPO.'
    return
  }

  try { Set-Location -LiteralPath $repo -ErrorAction Stop } catch { return }
  _dotfiles_run_agent $agent @rest
}

function gw {
  $wt = _dotfiles_worktrunk
  if (-not $wt) { _dotfiles_warn 'worktrunk (wt) is required.'; return }
  & $wt switch @args
}

function gwc {
  $wt = _dotfiles_worktrunk
  if (-not $wt) { _dotfiles_warn 'worktrunk (wt) is required.'; return }
  if ($args.Count -eq 0) {
    _dotfiles_warn 'usage: gwc <branch>'
    return
  }
  & $wt switch --create @args
}

# --- machine-local overrides (.zshrc_$(uname) equivalent) ---------------------
$localProfile = Join-Path $HOME '.config\powershell\profile.local.ps1'
if (Test-Path -LiteralPath $localProfile) { . $localProfile }

# --- tool init ----------------------------------------------------------------
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })
}
if (Get-Command starship -ErrorAction SilentlyContinue) {
  Invoke-Expression (& starship init powershell | Out-String)
}
$wtBin = _dotfiles_worktrunk
if ($wtBin) {
  Invoke-Expression (& $wtBin config shell init powershell | Out-String)
}
