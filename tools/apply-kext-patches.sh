#!/bin/bash
# 把本仓库 patches/ 里改好的 Info.plist 打进官方 VoodooI2C / VoodooI2CHID kext
# 用法:
#   bash apply-kext-patches.sh <VoodooI2C.kext 路径> <VoodooI2CHID.kext 路径>
# 例:
#   bash apply-kext-patches.sh ~/Downloads/VoodooI2C.kext ~/Downloads/VoodooI2CHID.kext
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PATCHES="$(dirname "$HERE")/patches"
[ $# -ge 2 ] || { echo "用法: bash apply-kext-patches.sh <VoodooI2C.kext> <VoodooI2CHID.kext>"; exit 1; }
I2C="$1"; HID="$2"
for k in "$I2C" "$HID"; do
  [ -d "$k" ] || { echo "找不到 kext: $k"; exit 1; }
done

backup() { # $1 = plist
  [ -f "$1" ] && cp -p "$1" "$1.bak-$(date +%Y%m%d-%H%M%S)"
}

echo "1) 替换 VoodooI2C 的 Info.plist（IOPCIMatch 加 0x7A7C，删 Services 依赖）"
backup "$I2C/Contents/Info.plist"
cp -f "$PATCHES/VoodooI2C-Info.plist" "$I2C/Contents/Info.plist"

echo "2) 替换 VoodooI2CHID 的 Info.plist（删 Touchscreen/Stylus，Multitouch 加 Transport=I2C）"
backup "$HID/Contents/Info.plist"
cp -f "$PATCHES/VoodooI2CHID-Info.plist" "$HID/Contents/Info.plist"

echo "3) 删除失效的 _CodeSignature（OC 注入不校验签名）"
rm -rf "$I2C/Contents/_CodeSignature" "$HID/Contents/_CodeSignature"

echo "完成。把这两个 kext 放进 EFI/OC/Kexts，并在 config.plist 的 Kernel > Add 里启用。"
