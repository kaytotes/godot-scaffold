# Renames this scaffold's C# namespace and project name throughout the repo.
# Run from anywhere; it always operates on the repo root (one level up from this script).

Set-Location (Join-Path $PSScriptRoot "..")

$OldNamespace = "Scaffold"
$OldProjectName = "godot-scaffold"
$OldRootNamespace = "godotscaffold"

$NewNamespace = (Read-Host "New C# namespace prefix (e.g. Pirate)").TrimEnd('.')

if ([string]::IsNullOrWhiteSpace($NewNamespace)) {
	Write-Error "Namespace cannot be empty."
	exit 1
}

if ($NewNamespace -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
	Write-Error "Namespace must be a valid C# identifier (letters, digits, underscore; can't start with a digit)."
	exit 1
}

$NewProjectName = Read-Host "New project name (e.g. pirate-game)"

if ([string]::IsNullOrWhiteSpace($NewProjectName)) {
	Write-Error "Project name cannot be empty."
	exit 1
}

if ($NewProjectName -notmatch '^[A-Za-z0-9_-]+$') {
	Write-Error "Project name may only contain letters, digits, hyphens, and underscores."
	exit 1
}

# Mirrors Godot's own default: RootNamespace is the project name with invalid characters stripped.
$NewRootNamespace = ($NewProjectName -replace '[^A-Za-z0-9]', '')

Write-Host ""
Write-Host "This will replace, in every .cs/.csproj/.sln/.godot/.tscn/.md file:"
Write-Host "  $OldNamespace.      -> $NewNamespace."
Write-Host "  $OldProjectName    -> $NewProjectName"
Write-Host "  $OldRootNamespace  -> $NewRootNamespace"
Write-Host "and rename $OldProjectName.csproj / .sln to match."
Write-Host ""
Write-Host "This repo has no git history to fall back on once checked out raw, so make sure"
Write-Host "you've committed or backed up before continuing."
$Confirm = Read-Host "Continue? [y/N]"

if ($Confirm -notin @('y', 'Y')) {
	Write-Host "Aborted."
	exit 0
}

$Files = Get-ChildItem -Path . -Recurse -File | Where-Object {
	$_.Extension -in ('.cs', '.csproj', '.sln', '.godot', '.tscn', '.md') -and
	$_.FullName -notmatch '\\\.git\\' -and
	$_.FullName -notmatch '\\\.godot\\' -and
	$_.FullName -notmatch '\\(bin|obj)\\'
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

foreach ($file in $Files) {
	$content = [System.IO.File]::ReadAllText($file.FullName)
	$updated = $content -replace "$OldNamespace\.", "$NewNamespace." `
		-replace [regex]::Escape($OldProjectName), $NewProjectName `
		-replace [regex]::Escape($OldRootNamespace), $NewRootNamespace

	if ($updated -ne $content) {
		[System.IO.File]::WriteAllText($file.FullName, $updated, $Utf8NoBom)
	}
}

if (Test-Path "$OldProjectName.csproj") {
	Rename-Item "$OldProjectName.csproj" "$NewProjectName.csproj"
}

if (Test-Path "$OldProjectName.sln") {
	Rename-Item "$OldProjectName.sln" "$NewProjectName.sln"
}

Write-Host ""
Write-Host "Done. Renamed to project '$NewProjectName' with namespace '$NewNamespace.'"
Write-Host "Re-open the project in Godot to let it regenerate the .godot/ cache."
