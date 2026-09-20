# Install chinese-novelist as a user-level Cursor skill on Windows.
$ErrorActionPreference = "Stop"
$SkillName = "chinese-novelist"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not (Test-Path (Join-Path $Root "SKILL.md"))) {
  throw "SKILL.md not found at $Root"
}

function Install-Into([string]$Dest) {
  $parent = Split-Path -Parent $Dest
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
  New-Item -ItemType Directory -Force -Path $Dest | Out-Null
  Copy-Item (Join-Path $Root "SKILL.md") $Dest
  Copy-Item (Join-Path $Root "references") $Dest -Recurse
  Copy-Item (Join-Path $Root "scripts") $Dest -Recurse
  Write-Host "installed: $Dest"
}

Install-Into (Join-Path $env:USERPROFILE ".cursor\skills\$SkillName")
Install-Into (Join-Path $env:USERPROFILE ".claude\skills\$SkillName")

Write-Host ""
Write-Host "chinese-novelist is installed globally."
Write-Host "Open a new Agent chat in any project, then type /chinese-novelist"
