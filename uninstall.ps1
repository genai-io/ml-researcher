#requires -Version 5.1
<#
  ml-researcher — remove the San persona and the files it installed.

  Local:   ./uninstall.ps1 [-User] [-Dir <path>]
  Remote:  irm https://raw.githubusercontent.com/genai-io/ml-researcher/main/uninstall.ps1 | iex
           & ([scriptblock]::Create((irm https://raw.githubusercontent.com/genai-io/ml-researcher/main/uninstall.ps1))) -User

  Removes the persona directory and the agents/commands/hooks files this persona
  owns (by exact name), and drops the persona selection only if it points at
  ml-researcher. Does NOT delete a scaffolded research project.
#>
[CmdletBinding()]
param(
  [switch]$User,
  [string]$Dir = ""
)
$ErrorActionPreference = "Stop"

$Persona  = "ml-researcher"
$Agents   = @("analyst", "critic", "experimenter", "literature", "modeler", "navigator")
$Commands = @("audit", "exp", "preflight", "research", "sandbox", "train")
$Hooks    = @("checks", "phase_gate", "preflight", "raw_data_guard", "sandbox_mode_banner", "stop_resume_check", "test_set_guard", "trace_append")

if ($User)    { $ConfDir = Join-Path $HOME ".san";          $Scope = "user" }
elseif ($Dir) { $ConfDir = Join-Path $Dir ".san";           $Scope = "dir" }
else          { $ConfDir = Join-Path (Get-Location) ".san"; $Scope = "project" }

$Dest = Join-Path (Join-Path $ConfDir "personas") $Persona
if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest; Write-Host "-> removed $Dest" }
else { Write-Host "-> no persona dir at $Dest (already gone)" }

foreach ($a in $Agents)   { Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path (Join-Path $ConfDir "agents")   "$a.md") }
foreach ($c in $Commands) { Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path (Join-Path $ConfDir "commands") "$c.md") }
foreach ($h in $Hooks)    { Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path (Join-Path $ConfDir "hooks")    "$h.sh") }
Write-Host "-> removed ml-researcher agents / commands / hook scripts"

$Settings = Join-Path $ConfDir "settings.json"
if ((Test-Path $Settings) -and ((Get-Content -Raw $Settings).Trim())) {
  $data = Get-Content -Raw $Settings | ConvertFrom-Json
  if ($data.PSObject.Properties.Name -contains "persona" -and $data.persona -eq $Persona) {
    $data.PSObject.Properties.Remove("persona")
    ($data | ConvertTo-Json -Depth 25) | Set-Content -Encoding UTF8 $Settings
    Write-Host "-> dropped `"persona`" selection from $Settings"
  } else {
    Write-Host "-> left `"persona`" selection unchanged (not pointing at $Persona)"
  }
}

Write-Host "note: the merged `"hooks`" block in $Settings (if present) was left in place;"
Write-Host "      remove it by hand if no other persona relies on those hook scripts."
Write-Host ""
Write-Host "OK ml-researcher uninstalled ($Scope scope)"
