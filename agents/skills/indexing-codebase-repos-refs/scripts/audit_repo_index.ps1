param(
    [string]$Repo = "."
)

$ErrorActionPreference = "Stop"

$RepoPath = (Resolve-Path -LiteralPath $Repo).Path
$DocsPath = Join-Path $RepoPath "docs"
$IndexPath = Join-Path $DocsPath "index.md"
$FailCount = 0
$WarnCount = 0

function Add-Fail([string]$Message) {
    Write-Output "FAIL: $Message"
    $script:FailCount++
}

function Add-Warn([string]$Message) {
    Write-Output "WARN: $Message"
    $script:WarnCount++
}

function Get-RelPath([string]$Path) {
    $relative = $Path.Substring($RepoPath.Length).TrimStart([char]'\', [char]'/')
    return ($relative -replace '\\', '/')
}

$RequiredDocs = @(
    "docs/index.md",
    "docs/entrypoints.md",
    "docs/layers.md",
    "docs/integrations.md",
    "docs/config-and-secrets.md",
    "docs/observability.md",
    "docs/deployment-and-infra.md",
    "docs/ownership.md",
    "docs/where-to-change.md"
)

foreach ($Required in $RequiredDocs) {
    if (-not (Test-Path -LiteralPath (Join-Path $RepoPath $Required))) {
        Add-Fail "missing required file: $Required"
    }
}

if (-not (Test-Path -LiteralPath $DocsPath) -or -not (Test-Path -LiteralPath $IndexPath)) {
    if ($FailCount -gt 0) { exit 1 }
    exit 0
}

$IndexText = Get-Content -LiteralPath $IndexPath -Raw

if ($IndexText -notmatch '\*\*UTC:\*\*\s*[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z') {
    Add-Fail "docs/index.md missing Generated UTC line"
}

$IndexGitMatch = [regex]::Match($IndexText, '\*\*Git:\*\*\s*`?([0-9a-f]{40})`?')
if (-not $IndexGitMatch.Success) {
    Add-Fail "docs/index.md missing Generated Git SHA"
} else {
    $HeadGit = ""
    try {
        $HeadGit = (& git -C $RepoPath rev-parse HEAD 2>$null).Trim()
    } catch {
        $HeadGit = ""
    }
    $IndexGit = $IndexGitMatch.Groups[1].Value
    if ($HeadGit -and $IndexGit -ne $HeadGit) {
        Add-Fail "docs/index.md Generated Git is stale: $IndexGit != HEAD $HeadGit"
    }
}

$DomainsPath = Join-Path $DocsPath "domains"
$DomainFiles = @()
if (Test-Path -LiteralPath $DomainsPath) {
    $DomainFiles = @(Get-ChildItem -LiteralPath $DomainsPath -Filter "*.md" -File | Sort-Object FullName)
}
if ($DomainFiles.Count -eq 0) {
    Add-Fail "docs/domains has no domain markdown files"
} else {
    foreach ($Domain in $DomainFiles) {
        $DomainRel = Get-RelPath $Domain.FullName
        $DomainLink = $DomainRel -replace '^docs/', ''
        if (-not $IndexText.Contains($DomainLink)) {
            Add-Fail "domain doc not linked from docs/index.md: $DomainRel"
        }
    }
}

$MarkdownFiles = @(Get-ChildItem -LiteralPath $DocsPath -Filter "*.md" -File -Recurse | Sort-Object FullName)
foreach ($Markdown in $MarkdownFiles) {
    $Text = Get-Content -LiteralPath $Markdown.FullName -Raw
    $Matches = [regex]::Matches($Text, '(?<!!)\[[^\]]+\]\(([^)]+)\)')
    foreach ($Match in $Matches) {
        $Target = $Match.Groups[1].Value.Split("#")[0].Replace("%20", " ")
        if (-not $Target) { continue }
        if ($Target -match '^(https?://|mailto:|#)') { continue }
        $TargetPath = Join-Path $Markdown.DirectoryName $Target
        if (-not (Test-Path -LiteralPath $TargetPath)) {
            Add-Fail "broken link in $(Get-RelPath $Markdown.FullName): $Target"
        }
    }
}

$TopLevelDocs = @(Get-ChildItem -LiteralPath $DocsPath -Filter "*.md" -File | Sort-Object FullName)
foreach ($Doc in $TopLevelDocs) {
    if ($Doc.Name -eq "index.md") { continue }
    if (-not $IndexText.Contains($Doc.Name)) {
        Add-Warn "top-level doc not linked from docs/index.md: $(Get-RelPath $Doc.FullName)"
    }
}

$IgnoredSubtrees = @("domains", "review", "reviews", "superpowers", "plans", "tmp", "generated")
$Subtrees = @(Get-ChildItem -LiteralPath $DocsPath -Directory | Sort-Object FullName)
foreach ($Subtree in $Subtrees) {
    if ($IgnoredSubtrees -contains $Subtree.Name) { continue }
    Add-Warn "docs subtree not covered by default index rules: $(Get-RelPath $Subtree.FullName)"
}

$AgentsPath = Join-Path $RepoPath "AGENTS.md"
if (-not (Test-Path -LiteralPath $AgentsPath)) {
    Add-Fail "repo AGENTS.md missing index instructions"
} else {
    $AgentsText = Get-Content -LiteralPath $AgentsPath -Raw
    foreach ($Phrase in @("docs/index.md", "ripgrep", "update the affected markdown", "Generated", "indexing-codebase-repos")) {
        if (-not $AgentsText.Contains($Phrase)) {
            Add-Warn "AGENTS.md may miss index rule phrase: '$Phrase'"
        }
    }
    if ((Test-Path -LiteralPath (Join-Path $RepoPath "go.mod")) -or (Test-Path -LiteralPath (Join-Path $RepoPath "go.work"))) {
        if (-not $AgentsText.Contains("gopls")) {
            Add-Warn "Go repo AGENTS.md may miss gopls MCP navigation guidance"
        }
    }
}

if ($FailCount -eq 0 -and $WarnCount -eq 0) {
    Write-Output "OK repo index audit passed"
} elseif ($FailCount -eq 0) {
    Write-Output "OK repo index audit passed with $WarnCount warning(s)"
}

if ($FailCount -gt 0) { exit 1 }
