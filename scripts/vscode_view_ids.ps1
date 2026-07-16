#Requires -Version 5.1
<#
.SYNOPSIS
    VSCode拡張機能のビューIDを一覧表示する (Windows用)
.DESCRIPTION
    インストール済み拡張機能のpackage.jsonを解析し、
    keybindings.jsonのwhen句で使えるコンテキストキーを出力する。
    - activeViewlet  : サイドバーコンテナがアクティブな時の値
    - activePanel    : パネルコンテナがアクティブな時の値
    - focusedView    : 個別ビューにフォーカスがある時の値
.PARAMETER Editor
    対象エディタ。"vscode"(既定) または "cursor"
.EXAMPLE
    .\vscode_view_ids.ps1
    .\vscode_view_ids.ps1 -Editor cursor
#>

param(
    [ValidateSet("vscode", "cursor")]
    [string]$Editor = "vscode"
)

$extDir = Join-Path $env:USERPROFILE ".${Editor}\extensions"

if (-not (Test-Path $extDir)) {
    Write-Error "拡張機能ディレクトリが見つかりません: $extDir"
    exit 1
}

$containers = [System.Collections.Generic.List[PSCustomObject]]::new()
$views      = [System.Collections.Generic.List[PSCustomObject]]::new()

Get-ChildItem $extDir -Directory | ForEach-Object {
    $pkgPath = Join-Path $_.FullName "package.json"
    if (-not (Test-Path $pkgPath)) { return }

    try {
        $pkg = Get-Content $pkgPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    } catch { return }

    $extName = $pkg.name

    # viewsContainers
    if ($pkg.contributes.viewsContainers) {
        $pkg.contributes.viewsContainers.PSObject.Properties | ForEach-Object {
            $location = $_.Name
            $_.Value | ForEach-Object {
                $containers.Add([PSCustomObject]@{
                    Extension = $extName
                    Location  = $location
                    ID        = $_.id
                    Title     = $_.title
                })
            }
        }
    }

    # views
    if ($pkg.contributes.views) {
        $pkg.contributes.views.PSObject.Properties | ForEach-Object {
            $container = $_.Name
            $_.Value | ForEach-Object {
                if ($_.id) {
                    $views.Add([PSCustomObject]@{
                        Extension = $extName
                        Container = $container
                        ID        = $_.id
                        Title     = $_.name
                    })
                }
            }
        }
    }
}

# --- activeViewlet / activePanel 出力 ---
Write-Host ""
Write-Host "=== activeViewlet / activePanel (コンテナID) ===" -ForegroundColor Cyan
Write-Host ""

foreach ($c in $containers | Sort-Object Extension, Location, ID) {
    $keyName = switch ($c.Location) {
        "activitybar"    { "activeViewlet  " }
        "panel"          { "activePanel    " }
        "secondarySidebar" { "activeAuxiliary" }
        default          { $c.Location.PadRight(15) }
    }
    $contextValue = "workbench.view.extension.$($c.ID)"
    Write-Host "[$($c.Extension)] $($c.Title)" -ForegroundColor Yellow
    Write-Host "  $keyName == '$contextValue'"
}

# --- focusedView 出力 ---
Write-Host ""
Write-Host "=== focusedView (個別ビューID) ===" -ForegroundColor Cyan
Write-Host ""

foreach ($v in $views | Sort-Object Extension, Container, ID) {
    Write-Host "  focusedView == '$($v.ID)'" -NoNewline
    Write-Host "   # [$($v.Extension)] in:$($v.Container)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "完了: $($containers.Count) コンテナ, $($views.Count) ビュー" -ForegroundColor Green
