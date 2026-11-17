<#
    把本仓库 patches/ 里改好的 Info.plist 打进官方 VoodooI2C / VoodooI2CHID kext（Windows 侧操作）
    用法（在解压好的 kext 目录上执行）：
    .\apply-kext-patches.ps1 -I2C "D:\kexts\VoodooI2C.kext" -HID "D:\kexts\VoodooI2CHID.kext"
#>
param(
    [Parameter(Mandatory=$true)][string]$I2C,
    [Parameter(Mandatory=$true)][string]$HID
)
$ErrorActionPreference = 'Stop'
$patches = Join-Path (Split-Path $PSScriptRoot -Parent) 'patches'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

foreach ($p in @(
    @{ Kext = $I2C; Plist = 'VoodooI2C-Info.plist' },
    @{ Kext = $HID; Plist = 'VoodooI2CHID-Info.plist' }
)) {
    $target = Join-Path $p.Kext 'Contents\Info.plist'
    if (-not (Test-Path $target)) { throw "找不到 $target" }
    $srcPlist = Join-Path $patches $p.Plist
    if (-not (Test-Path $srcPlist)) { throw "找不到 $srcPlist" }
    Copy-Item $target "$target.bak-$stamp" -Force
    Copy-Item $srcPlist $target -Force
    Write-Host ("已替换: " + $target)
    $sig = Join-Path $p.Kext 'Contents\_CodeSignature'
    if (Test-Path $sig) { Remove-Item $sig -Recurse -Force; Write-Host "  已删除 _CodeSignature" }
}
Write-Host ""
Write-Host "完成。把两个 kext 放进 EFI/OC/Kexts 并在 Kernel > Add 启用。" -ForegroundColor Green
