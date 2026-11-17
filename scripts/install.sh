#!/bin/bash
# 安装触控板配置（Legion Y7000P IRX10 / Raptor Lake-HX + GXT P5100）
# 用法: sudo bash install.sh [--revert]
set -u
[ "$(id -u)" = 0 ] || { echo "请用 sudo 运行"; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"

say(){ echo; echo "──── $* ────"; }

find_esp(){
  PHYS=$(/usr/sbin/diskutil info / 2>/dev/null | sed -n 's/^ *APFS Physical Store: *//p' | head -1)
  DISK=${PHYS%s*}; case "${DISK}" in disk[0-9]*) ;; *) DISK="" ;; esac
  [ -n "${DISK}" ] || return 1
  ESPDEV=$(/usr/sbin/diskutil list "${DISK}" 2>/dev/null | awk '/ EFI /{print $NF}' | head -1)
  [ -n "${ESPDEV}" ] || return 1
  /usr/sbin/diskutil mount "${ESPDEV}" >/dev/null 2>&1
  EFS=$(/usr/sbin/diskutil info "${ESPDEV}" 2>/dev/null | sed -n 's/^ *Mount Point: *//p')
  [ -n "${EFS}" ] && [ -d "${EFS}/EFI/OC" ]
}

find_esp || { echo "找不到 EFI 分区"; exit 1; }
CFG="${EFS}/EFI/OC/config.plist"
KX="${EFS}/EFI/OC/Kexts"

if [ "${1:-}" = "--revert" ]; then
  say "还原"
  BAK=$(ls -1t "${CFG}".bak-* 2>/dev/null | head -1)
  [ -n "${BAK}" ] && cp -f "${BAK}" "${CFG}" && echo "已还原: ${BAK}" || echo "没有找到备份"
  /sbin/reboot
  exit 0
fi

say "1. 备份配置"
cp -p "${CFG}" "${CFG}.bak-$(date +%Y%m%d-%H%M%S)" && echo "已备份"

say "2. 安装 kext"
for k in VoodooI2C VoodooI2CHID; do
  SRC="${ROOT}/kexts/${k}.kext"
  [ -d "${SRC}" ] || { echo "缺少 ${SRC}，请从 README 的链接下载后放入 kexts/"; exit 1; }
  rm -rf "${KX}/${k}.kext"
  cp -R "${SRC}" "${KX}/" && echo "  ${k}.kext"
done

say "3. 写入配置"
cp -f "${ROOT}/configs/config.plist.sample" "${CFG}"
cmp -s "${ROOT}/configs/config.plist.sample" "${CFG}" && echo "校验一致" || echo "校验失败！"

say "4. 完成"
echo "重启后验证："
echo "  ioreg -l -w0 -rc VoodooI2CDeviceNub | grep -E 'Interrupt Mode|gpioIRQ'"
echo "  期望: Interrupt Mode = GPIO / gpioIRQ = 8"