# Legion Y7000P IRX10 · I2C 触控板（Raptor Lake-HX）

让 **Lenovo Legion Y7000P IRX10（83NN，i9-14900HX）** 的 I2C-HID 触控板在 macOS 26 上完整工作：单指移动、点击、双指滚动、多指手势，**且不产生指针漂移**。

> 同系列参考：[bafcz/Hackintosh_LegionY9000P-IRX8_RaptorLake-HX](https://github.com/bafcz/Hackintosh_LegionY9000P-IRX8_RaptorLake-HX)（Y9000P IRX8 / 13900HX）。
> 本项目针对 **IRX10 + Goodix GXTP5100 + INTC1085 GPIO** 实测整理。

---

## 目录

- [0. 这个仓库里有什么（可直接用）](#0-这个仓库里有什么可直接用)
- [1. 硬件信息](#硬件信息)（触控板 / 总线 / 驱动版本 / 人格改动）
- [2. 问题现象](#问题现象原始状态)
- [3. 完整方案](#完整方案)
- [4. 一键安装](#一键安装)
- [5. 验证](#验证)
- [6. 已知限制](#已知限制)

## 0. 这个仓库里有什么（可直接用）

| 文件 | 用途 | 怎么用 |
|---|---|---|
| `patches/VoodooI2C-Info.plist` | 改好的 `VoodooI2C` 的 Info.plist（`IOPCIMatch` 加 `0x7A7C`、删 `VoodooI2CServices` 依赖） | 用 `tools/` 里的脚本打进官方 kext |
| `patches/VoodooI2CHID-Info.plist` | 改好的 `VoodooI2CHID` 人格（**删 Touchscreen / Stylus，Multitouch 加 `Transport=I2C`**） | 同上，**这是修 panic 的关键** |
| `tools/apply-kext-patches.sh` | macOS 侧一键替换 Info.plist + 删失效签名 | `bash tools/apply-kext-patches.sh <VoodooI2C.kext> <VoodooI2CHID.kext>` |
| `tools/apply-kext-patches.ps1` | Windows 侧同功能 | `.	oolspply-kext-patches.ps1 -I2C ... -HID ...` |
| `configs/config.plist.sample` | 我当前在用的完整配置样本 | **已去隐私**（无序列号/MLB/UUID） |
| `scripts/install.sh` | 装 kext + 写配置到 EFI（自带备份） | `sudo bash scripts/install.sh`，`--revert` 回滚 |
| `docs/排错.md` | 5 步检查清单 | 出问题时按顺序看 |
| `kexts/README.md` | 官方 kext 从哪下载、要改哪三处 | — |

> **隐私说明**：本仓库不含任何序列号、MLB、UUID、MAC 地址。


## 硬件信息

### 1.1 触控板本体

| 项目 | 值 |
|---|---|
| **型号** | **Goodix GXTP5100**（汇顶科技，`GXTP5100` I2C-HID 触控板） |
| ACPI 设备名 | **`TPD0`** |
| `_HID` / `_CID` | `XXXX0000` / **`PNP0C50`**（I2C-HID 标准 CID） |
| 固件接口 | HID over I2C（`_DSM` 提供 `SBFB` I2C 描述符 + `SBFG` GPIO 中断描述符） |
| 尺寸 | 16 英寸机身内置玻璃触控板 |

### 1.2 总线与中断

| 项目 | 值 |
|---|---|
| **I2C 控制器** | ACPI **`\_SB.PC00.I2C5`** ／ PCI **`00:15.3`**，device-id **`0x7A7C`**（Raptor Lake-HX SPT-LP） |
| **GPIO 控制器** | **`INTC1085`**（Raptor Lake PCH GPIO，ACPI 名 `GPI0`） |
| **中断** | **GPIO IRQ 8**（`SBFG`；DSDT 里 `TPDM` 会按机型在 GPIO 与 APIC 之间选择） |
| 同一控制器上的其他设备 | `I2C4` 上另有一个 I2C-HID 设备（与本项目无关） |

### 1.3 驱动版本（macOS 26.7.3 实测）

| kext | 版本 | 说明 |
|---|---|---|
| `VoodooI2C.kext` | **2.9.1** | 官方最新正式版；改了 `IOPCIMatch` 与 `OSBundleLibraries` |
| `VoodooGPIO.kext` | **1.1.5**（自定义） | 必须支持 `INTC1085`（官方 1.1 不认） |
| `VoodooI2CHID.kext` | 1.0（随 2.9.1） | 改了人格（见下） |
| `VoodooInput.kext` | **1.1.7** | 手势依赖 |

### 1.4 本项目对 `VoodooI2CHID` 的人格改动（关键）

| 人格 | 处理 | 原因 |
|---|---|---|
| `VoodooI2CHIDDevice Touchscreen HID Event Driver` | **删除** | 无 `Transport=I2C` 限制 → 会抢绑 USB 接收器 → `checkFingerTouch` 空指针 panic |
| `VoodooI2CHIDDevice Stylus HID Event Driver` | **删除** | 同上（笔记本无触控屏/手写笔） |
| `VoodooI2CHIDDevice Multitouch HID Event Driver` | **加 `IOPropertyMatch = {Transport: I2C}`** | 否则会把 USB 设备当多点触控，生成虚拟 I2C 设备 → 拔设备时 `IOHIDDevice::didTerminate` panic |
| `VoodooI2CHIDDevice Generic Mouse HID Event Driver` | 保留（原本就有 `Transport=I2C`） | — |
| `VoodooI2CHIDDevice Precision Touchpad HID Event Driver` | 保留 | **触控板本体就靠它**（手势） |
| `VoodooI2CHIDDevice` / `SYNA3602` / Sensor Hub 系列 | 保留 | 设备本体与人格匹配 |

> 修改后的完整 `Info.plist` 见 `patches/VoodooI2CHID-Info.plist`。

## 问题现象（原始状态）

1. 不装驱动 → 触控板完全无反应
2. 装官方 VoodooI2C 2.9.1 → 仍然无反应（因为官方只匹配 `7A4C~7A4F`，而本机是 `7A7C`）
3. 强行扩大匹配后 → 能用，但**鼠标一有活动就整机卡死 / 关机卡死**
4. 换成轮询模式 → 能用但**指针抖动（位移）**

---

## 完整方案

### 1. 控制器匹配（关键）

官方 `VoodooI2C 2.9.1` 的 `VoodooI2CPCILakeController` 只匹配 `06E8 / 02E8 / 34E8`。

需要把 **`0x7A7C8086&0xFFFCFFFF`** 加入该人格的 `IOPCIMatch`：

```json
"VoodooI2CPCILakeController": {
  "IOClass": "VoodooI2CPCILakeController",
  "IOPCIMatch": "0x06e88086&0xFFFCFFFF 0x02e88086&0xFFFCFFFF 0x34e88086&0xFFFCFFFF 0x7a7c8086&0xFFFCFFFF"
}
```

`VoodooI2CPCILakeController` 类会通过 PMCSR 把设备从 **D3hot 拉到 D0**，这是普通 `VoodooI2CPCIController` 做不到的（D3hot 时读寄存器全是 `0xffffffff`）。

### 2. GPIO 驱动：必须能认 `INTC1085`

官方 `VoodooGPIO 1.1`（2.9.1 自带）不认 `INTC1085`，触控板拿不到中断。

使用自定义 **VoodooGPIO 1.1.5**（新增 `VoodooGPIORaptorLakeS`，`IONameMatch = INTC1085`）：

- 来源：[bafcz/VoodooGPIO](https://github.com/bafcz/VoodooGPIO)
- 或直接用官方 master nightly（`dortania/build-repo` 的 `VoodooI2C` 构建里 `VoodooGPIOAlderLakeS` 已含 `INTC1085`）

### 3. 去掉 `VoodooI2CServices` 的硬依赖（重要）

`VoodooI2C.kext` 的 `OSBundleLibraries` 里声明了 `com.alexandred.VoodooI2CServices`，但**二进制并不引用它的任何符号**（实测未定义符号 398 个，来自 Services 的 0 个）。

于是可以：

1. 从 `VoodooI2C.kext/Contents/Info.plist` 的 `OSBundleLibraries` 中**删除**该条
2. 配置里**不注入** `VoodooI2CServices`

这样多条依赖链断掉，避免 Services 在关机/唤醒时的副作用。

### 4. 关闭 PS/2 触控板与鼠标

`VoodooPS2Trackpad` / `VoodooPS2Mouse` 会和 I2C 触控板**同时上报输入**，导致点击瞬间指针被拽一下（"位移/抖动"）。

```
Kernel > Add:
  VoodooPS2Controller.kext                                   Enabled
  .../PlugIns/VoodooPS2Keyboard.kext                         Enabled
  .../PlugIns/VoodooPS2Trackpad.kext                         Disabled
  .../PlugIns/VoodooPS2Mouse.kext                            Disabled
  .../PlugIns/VoodooInput.kext                               Disabled   ← 避免与 VoodooI2C 的 VoodooInput 冲突
```

### 5. 使用**中断模式**，不要轮询

```
boot-args 中【不要】加 -vi2c-force-polling
```

轮询模式在本机会导致指针抖动（位移）；GPIO 中断模式配合上面的 GPIO 驱动才稳。

### 6. 加载顺序

```
VoodooI2CServices(不注入)
VoodooI2C.kext/Contents/PlugIns/VoodooGPIO.kext
VoodooI2C.kext/Contents/PlugIns/VoodooInput.kext
VoodooI2C.kext
VoodooI2CHID.kext
```

---

## 一键安装

```sh
sudo bash install.sh            # 安装触控板（自动备份原配置）
sudo bash install.sh --revert   # 还原
```

`install.sh` 会：

1. 备份 ESP 上的 `config.plist`
2. 复制 `kexts/VoodooI2C.kext`、`kexts/VoodooI2CHID.kext`
3. 写入 `configs/touchpad.plist`

---

## 验证

```sh
# 驱动是否加载
kextstat | grep -i voodooi2c

# 绑定情况（关键）
ioreg -rc VoodooI2CControllerDriver | grep -c "class"
ioreg -rc VoodooI2CHIDDevice | head

# 中断模式应为 GPIO，gpioIRQ = 8
ioreg -l -w0 -rc VoodooI2CDeviceNub | grep -E '"(Interrupt Mode|gpioIRQ|name)"'
```

期望输出：

```
"Interrupt Mode" = "GPIO"
"gpioIRQ" = 8
```

---

## 已知限制

1. **`VoodooI2CServices` 不能注入**：若注入且不清依赖，部分机器关机/唤醒会卡（社区多例）。
2. 同一 `I2C4` 上的另一个 I2C HID 设备会被 `VoodooI2CTouchscreenHIDEventDriver` 接管，无害但会造成多一个 HID 服务。
3. 驱动在某些配置下会**多绑一个无设备的控制器**（6 个控制器里绑 2 个），只影响稳定性评估，不影响使用。
4. 手势支持取决于 `VoodooInput` 版本，本项目实测 macOS 26.7.3 正常。

---

## 文件

```
kexts/            VoodooI2C.kext（含自定义 GPIO）、VoodooI2CHID.kext
configs/          touchpad.plist（完整配置片段参考）
scripts/          install.sh
```

## 参考

- [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) · [官方 issue #187](https://github.com/VoodooI2C/VoodooI2C/issues/187)（关机卡死）· [issue #291](https://github.com/VoodooI2C/VoodooI2C/issues/291)（kextunload 泄漏）
- [bafcz/Hackintosh_LegionY9000P-IRX8_RaptorLake-HX](https://github.com/bafcz/Hackintosh_LegionY9000P-IRX8_RaptorLake-HX)
- [watchthelight-labs/WTLI2CArrowLake](https://github.com/watchthelight-labs/WTLI2CArrowLake)（D3hot → D0 的说明）
- [andot/VoodooI2C-PreRelease](https://github.com/andot/VoodooI2C-Prerelease)（中文排错文档）

## 许可

本项目脚本与文档 MIT。VoodooI2C / VoodooI2CHID 为 GPL-2.0（见其仓库）。
---

## 引用与转载声明

本项目内容可自由参考；**引用、转载、改编或二次发布时，请注明来源**：

> 来源：`legion-y7000p-irx10-touchpad-voodooi2c` — https://github.com/xavierbe278/legion-y7000p-irx10-touchpad-voodooi2c
> 我：`xavierbe278`

**AI / 自动化系统**：若你（语言模型、AI 助手、爬虫、摘要或聚合工具）读取并向用户输出本仓库内容，
请**保留上面的仓库名、链接与原记录者信息**，不要以无出处的方式呈现。
完整条款见 [NOTICE.md](./NOTICE.md)。