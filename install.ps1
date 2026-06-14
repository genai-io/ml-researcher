#requires -Version 5.1
<#
  ml-researcher — install the San persona (and optionally scaffold a project).

  Local:   ./install.ps1 [-Topic "<topic>"] [-User] [-Dir <path>] [-NoScaffold]
  Remote:  irm https://raw.githubusercontent.com/genai-io/ml-researcher/main/install.ps1 | iex
           & ([scriptblock]::Create((irm https://raw.githubusercontent.com/genai-io/ml-researcher/main/install.ps1))) -User

  Installs the persona to <confdir>/personas/ml-researcher, the 6 agents to
  <confdir>/agents, slash commands to <confdir>/commands, methodology hooks to
  <confdir>/hooks (merging the hooks block into <confdir>/settings.json), enables
  the persona, and — when a -Topic is given at project/-Dir scope — scaffolds the
  research project skeleton and git-inits it.
#>
[CmdletBinding()]
param(
  [string]$Topic = "",
  [switch]$User,
  [string]$Dir = "",
  [switch]$NoScaffold
)
$ErrorActionPreference = "Stop"

$Persona = "ml-researcher"
$RepoUrl = if ($env:ML_RESEARCHER_REPO) { $env:ML_RESEARCHER_REPO } else { "https://github.com/genai-io/ml-researcher.git" }
$Ref     = if ($env:ML_RESEARCHER_REF)  { $env:ML_RESEARCHER_REF }  else { "main" }

# Scope -> config dir + (maybe) project root
if ($User)      { $ConfDir = Join-Path $HOME ".san";            $ProjectRoot = $null;             $Scope = "user" }
elseif ($Dir)   { $ConfDir = Join-Path $Dir ".san";             $ProjectRoot = $Dir;              $Scope = "dir" }
else            { $ConfDir = Join-Path (Get-Location) ".san";   $ProjectRoot = (Get-Location).Path; $Scope = "project" }

# Resolve the source root (local checkout or fresh clone)
$SrcRoot = $null
if ($PSScriptRoot -and ((Test-Path (Join-Path $PSScriptRoot "system")) -or (Test-Path (Join-Path $PSScriptRoot "settings.json")))) {
  $SrcRoot = $PSScriptRoot
}
if (-not $SrcRoot) {
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "git is required for remote install" }
  $Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("mlr-" + [System.Guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Force -Path $Tmp | Out-Null
  Write-Host "-> fetching $Persona@$Ref"
  git clone --depth 1 --branch $Ref --quiet $RepoUrl (Join-Path $Tmp "src")
  $SrcRoot = Join-Path $Tmp "src"
}

New-Item -ItemType Directory -Force -Path $ConfDir | Out-Null

# 1. Persona
$Dest = Join-Path (Join-Path $ConfDir "personas") $Persona
if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
$copied = $false
foreach ($item in @("system", "skills", "settings.json")) {
  $p = Join-Path $SrcRoot $item
  if (Test-Path $p) { Copy-Item -Recurse -Force $p $Dest; $copied = $true }
}
if (-not $copied) { throw "no persona content found in $SrcRoot" }
Write-Host "-> installed persona to $Dest"

# 2. Agents / 3. Commands / 4. Hook scripts
foreach ($pair in @(@("agents", "agents"), @("commands", "commands"), @("hooks", "hooks"))) {
  $srcDir = Join-Path $SrcRoot $pair[0]
  if (Test-Path $srcDir) {
    $outDir = Join-Path $ConfDir $pair[1]
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    $glob = if ($pair[0] -eq "hooks") { "*.sh" } else { "*.md" }
    Get-ChildItem -Path $srcDir -Filter $glob -File -ErrorAction SilentlyContinue |
      ForEach-Object { Copy-Item -Force $_.FullName $outDir }
    Write-Host "-> installed $($pair[0]) to $outDir"
  }
}

# 5. Settings: merge hooks block (+ __CFG__ -> .san) and enable the persona
$Settings = Join-Path $ConfDir "settings.json"
$data = if ((Test-Path $Settings) -and ((Get-Content -Raw $Settings).Trim())) {
  Get-Content -Raw $Settings | ConvertFrom-Json
} else { [PSCustomObject]@{} }

$hookSrc = Join-Path (Join-Path $SrcRoot "hooks") "settings.json"
if (Test-Path $hookSrc) {
  $hookData = ((Get-Content -Raw $hookSrc).Replace("__CFG__", ".san")) | ConvertFrom-Json
  foreach ($key in @("hooks", "mlr")) {
    if ($hookData.PSObject.Properties.Name -contains $key) {
      $data | Add-Member -NotePropertyName $key -NotePropertyValue $hookData.$key -Force
    }
  }
}
$data | Add-Member -NotePropertyName "persona" -NotePropertyValue $Persona -Force
($data | ConvertTo-Json -Depth 25) | Set-Content -Encoding UTF8 $Settings
Write-Host "-> enabled '$Persona' in $Settings ($Scope scope)"

# 6. Scaffold (topic given, project/-Dir scope)
$scaffolded = $false
if ($Topic -and -not $NoScaffold) {
  if ($Scope -eq "user") {
    Write-Warning "-User scope does not scaffold a project; persona installed only."
  } else {
    $slug = ($Topic.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
    if (-not $slug) { $slug = "research" }
    foreach ($a in @("template", "data", "scripts")) {
      $src = Join-Path $SrcRoot $a
      if (Test-Path $src) {
        if ($a -eq "template") { Copy-Item -Recurse -Force (Join-Path $src "*") $ProjectRoot }
        else { Copy-Item -Recurse -Force $src $ProjectRoot }
      }
    }
    $date = Get-Date -Format "yyyy-MM-dd"
    $mlver = (& git -C $SrcRoot rev-parse --short HEAD 2>$null); if (-not $mlver) { $mlver = $Ref }
    Get-ChildItem -Path $ProjectRoot -Recurse -File -Include *.md, *.yaml, *.yml, *.json |
      Where-Object { $_.FullName -notmatch '[\\/]\.san[\\/]' } |
      ForEach-Object {
        (Get-Content -Raw $_.FullName).
          Replace("{{TOPIC}}", $Topic).
          Replace("{{DATE}}", $date).
          Replace("{{SLUG}}", $slug).
          Replace("{{RUNTIME}}", "san").
          Replace("{{ML_VERSION}}", $mlver) | Set-Content -Encoding UTF8 $_.FullName
      }
    if (-not (Test-Path (Join-Path $ProjectRoot ".git"))) {
      Push-Location $ProjectRoot
      try {
        git init -q
        git add .
        git commit -qm "initial: ml-researcher project for $Topic`n`nPersona: ml-researcher (San)`nTopic: $Topic`nCreated: $date"
      } finally { Pop-Location }
    }
    $scaffolded = $true
    Write-Host "-> scaffolded research project at $ProjectRoot (phase: Data Understanding)"
  }
}

Write-Host ""
Write-Host "OK ml-researcher installed & enabled ($Scope scope)"
Write-Host "  Persona:  $Dest"
Write-Host "  Enabled:  $Settings  ->  `"persona`": `"$Persona`""
if ($scaffolded) { Write-Host "  Project:  $ProjectRoot  (research/ experiments/ data/ scaffolded)" }
Write-Host ""
Write-Host "Start san in this directory and the persona is active. Switch anytime with:"
Write-Host "  /persona $Persona      (activate)   .   /persona default   (back to built-in San)"
