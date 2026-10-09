# Claude Code の設定ファイルのリンクを行う (Windows 向け)
# シンボリックリンク作成には「開発者モード」の有効化、または管理者権限での実行が必要
# local-paths.md は環境ごとに編集するためコピーで配置する (settings.local.json などは管理対象外)
$ErrorActionPreference = 'Stop'

$ScriptDir = $PSScriptRoot
$ClaudeDir = Join-Path $HOME '.claude'
$Files = @('CLAUDE.md', 'settings.json', 'keybindings.json')

if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir | Out-Null
    Write-Host "[mkdir] $ClaudeDir"
}

foreach ($name in $Files) {
    $src = Join-Path $ScriptDir $name
    $dst = Join-Path $ClaudeDir $name
    # Test-Path はリンク切れのシンボリックリンクを検出できないため Get-Item で確認する
    $item = Get-Item -Path $dst -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -eq 'SymbolicLink' -and "$($item.Target)" -eq $src) {
        Write-Host "[skip] $dst -> $src"
    } elseif ($item) {
        Write-Warning "$dst already exists. skipped."
    } else {
        New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
        Write-Host "[link] $dst -> $src"
    }
}

# skills/ の下の各スキルを ~/.claude/skills/<スキル名> にリンクする (~/.claude/skills には管理対象外のスキルもあるため、フォルダごとではなくスキルごとにリンクする)
$SkillsSrc = Join-Path $ScriptDir 'skills'
$SkillsDst = Join-Path $ClaudeDir 'skills'
if (Test-Path $SkillsSrc) {
    if (-not (Test-Path $SkillsDst)) {
        New-Item -ItemType Directory -Path $SkillsDst | Out-Null
        Write-Host "[mkdir] $SkillsDst"
    }
    foreach ($skill in Get-ChildItem -Path $SkillsSrc -Directory) {
        $src = $skill.FullName
        $dst = Join-Path $SkillsDst $skill.Name
        $item = Get-Item -Path $dst -Force -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType -eq 'SymbolicLink' -and "$($item.Target)" -eq $src) {
            Write-Host "[skip] $dst -> $src"
        } elseif ($item) {
            Write-Warning "$dst already exists. skipped."
        } else {
            New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
            Write-Host "[link] $dst -> $src"
        }
    }
}

# local-paths.md は環境ごとに編集するためリンクではなくコピーする (既存なら上書きしない)
$src = Join-Path $ScriptDir 'local-paths.md'
$dst = Join-Path $ClaudeDir 'local-paths.md'
if (Test-Path $dst) {
    Write-Host "[skip] $dst already exists"
} else {
    Copy-Item -Path $src -Destination $dst
    Write-Host "[copy] $src -> $dst"
    Write-Host '[info] 必要に応じて ~/.claude/local-paths.md のパス (META_DIR など) をこの環境向けに編集してください'
}

Write-Host '[done]'
