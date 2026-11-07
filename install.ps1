#requires -Version 5.1
<#
.SYNOPSIS
Install the lightweight Vim configuration for the current user.
.DESCRIPTION
Requires the adjacent vimrc and plugins.tsv files. Git is needed unless
-NoPlugins is used. Existing configuration is backed up before replacement.
Existing plugins are kept by default; -Update stages safe Git updates first.
No administrator rights or changes to the PowerShell execution policy are used.
.PARAMETER NoPlugins
Install the configuration without downloading or updating plugins.
.PARAMETER Update
Update managed plugins with a fast-forward Git pull in a temporary copy.
.PARAMETER TargetHome
Use this directory instead of the current user's Vim home directory.
.EXAMPLE
.\install.ps1
.EXAMPLE
.\install.ps1 -NoPlugins
.EXAMPLE
.\install.ps1 -Update
#>
[CmdletBinding()]
param(
    [switch]$NoPlugins,
    [switch]$Update,
    [string]$TargetHome
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-ExistingItem {
    param([string]$LiteralPath)
    # Get-Item also recognizes file links; Test-Path alone misses broken links.
    $found = @(Get-Item -LiteralPath $LiteralPath -Force -ErrorAction SilentlyContinue)
    if ($found.Count -gt 0) { return $found[0] }
    return $null
}

function Test-IsLink {
    param($Item)
    return ($null -ne $Item -and
        ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
}

function Ensure-Directory {
    param([string]$LiteralPath)
    $item = Get-ExistingItem $LiteralPath
    if ($null -ne $item -and -not $item.PSIsContainer) {
        throw "Expected a directory: $LiteralPath"
    }
    [IO.Directory]::CreateDirectory($LiteralPath) | Out-Null
}

function Quote-PowerShellString {
    param([string]$Value)
    return "'" + $Value.Replace("'", "''") + "'"
}

function Invoke-Git {
    param(
        [string[]]$Arguments,
        [switch]$Capture,
        [int[]]$AllowedExitCodes = @(0)
    )
    # Avoid user/global hooks while preparing plugin copies. Git's TLS and
    # normal proxy configuration remain enabled.
    $gitArguments = @('-c', "core.hooksPath=$script:GitHookDirectory") + $Arguments
    $previousPreference = $ErrorActionPreference
    $previousPrompt = $env:GIT_TERMINAL_PROMPT
    $output = @()
    try {
        # Windows PowerShell 5.1 can treat native stderr as ErrorRecord objects.
        # Git's exit status, rather than progress on stderr, decides success.
        $ErrorActionPreference = 'Continue'
        $env:GIT_TERMINAL_PROMPT = '0'
        if ($Capture) {
            $output = @(& $script:GitExecutable @gitArguments 2>&1)
        }
        else {
            & $script:GitExecutable @gitArguments | Out-Host
        }
        $gitExit = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
        $env:GIT_TERMINAL_PROMPT = $previousPrompt
    }
    if ($AllowedExitCodes -notcontains $gitExit) {
        if ($Capture -and $output.Count -gt 0) {
            Write-Host (($output | ForEach-Object { $_.ToString() }) -join "`n")
        }
        throw "Git failed with exit code $gitExit."
    }
    if ($Capture) {
        return (($output | ForEach-Object { $_.ToString() }) -join "`n").Trim()
    }
}

function Assert-UpdateablePlugin {
    param($Plugin, [string]$Path)
    $item = Get-ExistingItem $Path
    $gitDir = Get-ExistingItem (Join-Path $Path '.git')
    if (Test-IsLink $item) {
        throw "Refusing to update a plugin link: $Path. Update its repository yourself."
    }
    if ($null -eq $gitDir -or -not $gitDir.PSIsContainer -or (Test-IsLink $gitDir)) {
        throw "Update needs a standalone Git checkout, not a worktree or link: $Path"
    }
    if ($null -ne (Get-ExistingItem (Join-Path $gitDir.FullName 'commondir'))) {
        throw "Shared Git directories cannot be staged safely: $Path"
    }
    $worktree = Invoke-Git -Arguments @('-C', $Path, 'config', '--get', 'core.worktree') -Capture -AllowedExitCodes @(0, 1)
    if (-not [string]::IsNullOrEmpty($worktree)) {
        throw "A checkout with core.worktree cannot be staged safely: $Path"
    }
    $origin = Invoke-Git -Arguments @('-C', $Path, 'remote', 'get-url', 'origin') -Capture
    if ($origin -cne $Plugin.Url) {
        throw "Unexpected origin for $($Plugin.Name). Expected $($Plugin.Url). Existing files were kept."
    }
    $branch = Invoke-Git -Arguments @('-C', $Path, 'symbolic-ref', '--quiet', '--short', 'HEAD') -Capture -AllowedExitCodes @(0, 1)
    if ($branch -cne $Plugin.Branch) {
        throw "Expected branch '$($Plugin.Branch)' for $($Plugin.Name). Existing files were kept."
    }
    $changes = Invoke-Git -Arguments @('-C', $Path, 'status', '--porcelain', '--untracked-files=no') -Capture
    if (-not [string]::IsNullOrEmpty($changes)) {
        throw "Tracked plugin files have local changes: $Path. Commit or resolve them before -Update."
    }
}

if ($NoPlugins -and $Update) {
    throw '-NoPlugins and -Update cannot be used together.'
}

$sourceVimrc = Join-Path $PSScriptRoot 'vimrc'
$sourceManifest = Join-Path $PSScriptRoot 'plugins.tsv'
foreach ($requiredFile in @($sourceVimrc, $sourceManifest)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Missing file: $requiredFile. Extract the whole bundle into one directory first."
    }
}

$onWindows = [IO.Path]::DirectorySeparatorChar -eq '\'
if ([string]::IsNullOrWhiteSpace($TargetHome)) {
    if (-not [string]::IsNullOrWhiteSpace($env:HOME)) {
        $TargetHome = $env:HOME
    }
    else {
        $TargetHome = [Environment]::GetFolderPath('UserProfile')
    }
}
if ([string]::IsNullOrWhiteSpace($TargetHome)) {
    throw 'The user home directory could not be determined. Pass -TargetHome explicitly.'
}
$targetRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetHome)
$targetRoot = [IO.Path]::GetFullPath($targetRoot)
if ($onWindows) {
    $vimDirectory = Join-Path $targetRoot 'vimfiles'
    # Vim on Windows checks _vimrc before .vimrc. Replace the active candidate.
    if ($null -ne (Get-ExistingItem (Join-Path $targetRoot '_vimrc'))) {
        $targetVimrc = Join-Path $targetRoot '_vimrc'
    }
    elseif ($null -ne (Get-ExistingItem (Join-Path $targetRoot '.vimrc'))) {
        $targetVimrc = Join-Path $targetRoot '.vimrc'
    }
    else {
        $targetVimrc = Join-Path $targetRoot '_vimrc'
    }
}
else {
    $vimDirectory = Join-Path $targetRoot '.vim'
    $targetVimrc = Join-Path $targetRoot '.vimrc'
}
$oldConfigItem = Get-ExistingItem $targetVimrc
if ($null -ne $oldConfigItem -and $oldConfigItem.PSIsContainer) {
    throw "The vimrc path is a directory: $targetVimrc"
}

$plugins = @()
$seenNames = @{}
foreach ($line in [IO.File]::ReadAllLines($sourceManifest)) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) { continue }
    $fields = $line.Split([char]9)
    if ($fields.Count -ne 3) { throw 'plugins.tsv needs three tab-separated columns: name, URL, branch.' }
    $name = $fields[0].Trim()
    $url = $fields[1].Trim()
    $branch = $fields[2].Trim()
    if ($name -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$' -or
        $url -notmatch '^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git$' -or
        $branch -notmatch '^[A-Za-z0-9][A-Za-z0-9._/-]*$' -or
        $branch.Contains('..')) {
        throw "Invalid plugin manifest row: $name"
    }
    if ($seenNames.ContainsKey($name)) { throw "Duplicate plugin name in manifest: $name" }
    $seenNames[$name] = $true
    $plugins += [pscustomobject]@{ Name = $name; Url = $url; Branch = $branch }
}
if ($plugins.Count -eq 0) { throw 'plugins.tsv contains no plugins.' }

if (-not $NoPlugins) {
    $gitCommand = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $gitCommand) {
        throw 'Git was not found on PATH. Install Git and open a new PowerShell, or use -NoPlugins.'
    }
    $script:GitExecutable = $gitCommand.Source
}

$runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
$packageDirectory = Join-Path $vimDirectory 'pack/lightvim/start'
$backupDirectory = Join-Path $vimDirectory ("lightvim-backups/$runId")
$backupVimrc = Join-Path $backupDirectory 'vimrc.previous'
$stageDirectory = $null
$configTemp = $null
$configBackedUp = $false
$configChanged = $true
$backupUsed = $false
$prepared = @()
$committed = @()

try {
    Ensure-Directory $targetRoot
    Ensure-Directory $vimDirectory
    if (-not $NoPlugins) {
        Ensure-Directory $packageDirectory
        $stageDirectory = Join-Path $vimDirectory ('.lightvim-stage-' + [Guid]::NewGuid().ToString('N'))
        Ensure-Directory $stageDirectory
        $script:GitHookDirectory = Join-Path $stageDirectory 'empty-hooks'
        Ensure-Directory $script:GitHookDirectory
        foreach ($plugin in $plugins) {
            $destination = Join-Path $packageDirectory $plugin.Name
            $existing = Get-ExistingItem $destination
            $staged = Join-Path $stageDirectory $plugin.Name
            if ($null -ne $existing) {
                if (-not $existing.PSIsContainer) { throw "Plugin path is not a directory: $destination" }
                if (-not $Update) {
                    Write-Host "Keeping existing plugin: $($plugin.Name)"
                    continue
                }
                Assert-UpdateablePlugin $plugin $destination
                Write-Host "Checking update: $($plugin.Name)"
                $oldHead = Invoke-Git -Arguments @('-C', $destination, 'rev-parse', 'HEAD') -Capture
                Copy-Item -LiteralPath $destination -Destination $staged -Recurse -Force
                Invoke-Git -Arguments @('-C', $staged, 'pull', '--quiet', '--ff-only', '--no-rebase', '--no-recurse-submodules', 'origin', $plugin.Branch)
                $newHead = Invoke-Git -Arguments @('-C', $staged, 'rev-parse', 'HEAD') -Capture
                if ($oldHead -ceq $newHead) {
                    Write-Host "Already current: $($plugin.Name)"
                    continue
                }
            }
            else {
                Write-Host "Downloading plugin: $($plugin.Name)"
                Invoke-Git -Arguments @('clone', '--quiet', '--depth', '1', '--single-branch', '--branch', $plugin.Branch, '--', $plugin.Url, $staged)
            }
            $prepared += [pscustomobject]@{
                Name = $plugin.Name; Source = $staged; Destination = $destination
                HadPrevious = ($null -ne $existing); Backup = $null
            }
        }
    }

    # Persistent undo, swap and backup files live outside working repositories.
    $stateRoot = Join-Path $vimDirectory 'lightvim-state'
    $stateDirectories = @($stateRoot)
    foreach ($subdir in @('undo', 'swap', 'backup')) {
        $stateDirectories += Join-Path $stateRoot $subdir
    }
    foreach ($directory in $stateDirectories) { Ensure-Directory $directory }
    if (-not $onWindows) {
        $chmod = Get-Command chmod -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $chmod) {
            & $chmod.Source '700' @stateDirectories
            if ($LASTEXITCODE -ne 0) { throw 'Could not set private permissions on Vim state directories.' }
        }
    }

    if ($null -ne $oldConfigItem -and -not (Test-IsLink $oldConfigItem)) {
        $sourceHash = (Get-FileHash -LiteralPath $sourceVimrc -Algorithm SHA256).Hash
        $targetHash = (Get-FileHash -LiteralPath $targetVimrc -Algorithm SHA256).Hash
        $configChanged = $sourceHash -cne $targetHash
    }
    if ($configChanged) {
        $configTemp = Join-Path $targetRoot ('.lightvim-vimrc-' + [Guid]::NewGuid().ToString('N') + '.tmp')
        [IO.File]::Copy($sourceVimrc, $configTemp, $false)
    }

    # All downloads and pulls have succeeded. Original checkouts are retained
    # in the backup directory before the staged versions become active.
    foreach ($entry in $prepared) {
        if ($entry.HadPrevious) {
            $entry.Backup = Join-Path $backupDirectory ("plugins/$($entry.Name)")
            Ensure-Directory (Split-Path -Parent $entry.Backup)
            [IO.Directory]::Move($entry.Destination, $entry.Backup)
            $backupUsed = $true
        }
        try {
            [IO.Directory]::Move($entry.Source, $entry.Destination)
        }
        catch {
            if ($entry.HadPrevious) { [IO.Directory]::Move($entry.Backup, $entry.Destination) }
            throw
        }
        $committed += $entry
    }

    if ($configChanged) {
        if ($null -ne $oldConfigItem) {
            Ensure-Directory $backupDirectory
            # Moving the link itself preserves its target; never write through it.
            [IO.File]::Move($targetVimrc, $backupVimrc)
            $configBackedUp = $true
            $backupUsed = $true
        }
        try {
            [IO.File]::Move($configTemp, $targetVimrc)
            $configTemp = $null
        }
        catch {
            if ($configBackedUp) {
                [IO.File]::Move($backupVimrc, $targetVimrc)
                $configBackedUp = $false
            }
            throw
        }
        Write-Host "Installed vimrc: $targetVimrc"
    }
    else {
        Write-Host "Vimrc is already current: $targetVimrc"
    }
}
catch {
    # Roll back plugin moves if activation failed. Network failures never
    # reach this phase. Every removed active directory returns to our stage.
    for ($index = $committed.Count - 1; $index -ge 0; $index--) {
        $entry = $committed[$index]
        try {
            [IO.Directory]::Move($entry.Destination, $entry.Source)
            if ($entry.HadPrevious) { [IO.Directory]::Move($entry.Backup, $entry.Destination) }
        }
        catch {
            Write-Warning "Could not fully restore $($entry.Name). Its prior copy is at: $($entry.Backup)"
        }
    }
    throw
}
finally {
    if ($null -ne $configTemp -and [IO.File]::Exists($configTemp)) {
        Remove-Item -LiteralPath $configTemp -Force -ErrorAction SilentlyContinue
    }
    if ($null -ne $stageDirectory -and [IO.Directory]::Exists($stageDirectory)) {
        Remove-Item -LiteralPath $stageDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Optional documentation and revision reporting must not undo a good install.
$sourceExample = Join-Path $PSScriptRoot 'vimrc.local.example'
$targetExample = Join-Path $targetRoot '.vimrc.local.example'
try {
    if ([IO.File]::Exists($sourceExample) -and $null -eq (Get-ExistingItem $targetExample)) {
        [IO.File]::Copy($sourceExample, $targetExample, $false)
    }
}
catch { Write-Warning "The configuration is installed, but the local example could not be copied: $($_.Exception.Message)" }

if (-not $NoPlugins) {
    try {
        # The earlier hook directory has been removed. A missing hook directory
        # also disables hooks and no repository is changed by rev-parse.
        $revisionLines = @('# name' + "`t" + 'commit' + "`t" + 'repository')
        foreach ($plugin in $plugins) {
            $path = Join-Path $packageDirectory $plugin.Name
            $commit = Invoke-Git -Arguments @('-C', $path, 'rev-parse', 'HEAD') -Capture
            $revisionLines += $plugin.Name + "`t" + $commit + "`t" + $plugin.Url
        }
        $revisionPath = Join-Path $vimDirectory 'lightvim-plugin-revisions.tsv'
        if (Test-IsLink (Get-ExistingItem $revisionPath)) {
            throw "The revision log is a link; it was left unchanged: $revisionPath"
        }
        [IO.File]::WriteAllLines($revisionPath, [string[]]$revisionLines, (New-Object Text.UTF8Encoding($false)))
    }
    catch { Write-Warning "The configuration is installed, but plugin revisions could not be recorded: $($_.Exception.Message)" }
}

Write-Host "Plugin directory: $packageDirectory"
if ($NoPlugins) {
    Write-Host 'Plugin download skipped. Vim will use the light fallback theme until Everforest is installed.'
}
else {
    Write-Host 'For plugin help, run :helptags ALL once.'
}
if ($backupUsed) { Write-Host "Backup directory: $backupDirectory" }
if ($configBackedUp) {
    Write-Host 'To restore the previous vimrc, close Vim and run:'
    Write-Host ('  Move-Item -LiteralPath {0} -Destination {1}' -f
        (Quote-PowerShellString $targetVimrc), (Quote-PowerShellString "$targetVimrc.lightvim-installed-$runId"))
    Write-Host ('  Move-Item -LiteralPath {0} -Destination {1}' -f
        (Quote-PowerShellString $backupVimrc), (Quote-PowerShellString $targetVimrc))
}
if ($Update -and $backupUsed) {
    Write-Host 'Any updated plugin versions were retained under the backup directory (plugins/).'
}
if ($null -eq (Get-Command vim -CommandType Application -ErrorAction SilentlyContinue)) {
    Write-Warning 'Vim is not on PATH. Install Vim 8.2 or newer (9.x recommended), then open a new terminal.'
}
if (-not [string]::IsNullOrEmpty($env:VIMINIT)) {
    Write-Warning 'VIMINIT is set; Vim may use it instead of this vimrc. Check :echo $MYVIMRC in Vim.'
}
Write-Host 'Done. Open Vim and run :LightVimHealth.'
