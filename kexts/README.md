# kexts —— 我实际在用的驱动（已改好，可直接用）

| kext | 版本 | 我做了什么改动 |
|---|---|---|
| `VoodooI2C.kext` | 2.9.1 | ① `VoodooI2CPCILakeController.IOPCIMatch` 加入 `0x7a7c8086&0xFFFCFFFF`<br>② 删除 `OSBundleLibraries` 里的 `com.alexandred.VoodooI2CServices` 依赖<br>③ 内含自定义 **VoodooGPIO 1.1.5**（`Contents/PlugIns/VoodooGPIO.kext`，支持 `INTC1085`） |
| `VoodooI2CHID.kext` | 1.0 | ① 删除 `VoodooI2CHIDDevice Touchscreen HID Event Driver`<br>② 删除 `VoodooI2CHIDDevice Stylus HID Event Driver`<br>③ 给 `VoodooI2CHIDDevice Multitouch HID Event Driver` 加 `IOPropertyMatch = { Transport = I2C }` |
| `VoodooInput.kext` | 1.1.7 | 未改动（手势依赖它） |

> `VoodooInput.kext` 正常应该放在 `VoodooI2C.kext/Contents/PlugIns/` 里；这里单独放了一份，
> 方便你在 EFI 里单独列出（`VoodooI2C.kext/Contents/PlugIns/VoodooInput.kext` 这条路径）。

## 怎么用

### 方式一：直接用这里的 kext（最省事）

```
EFI/OC/Kexts/
├── VoodooI2C.kext          ← 用这里的
├── VoodooI2CHID.kext       ← 用这里的
```

然后在 `config.plist` 的 `Kernel > Add` 里按顺序启用：

```
1. VoodooI2C.kext/Contents/PlugIns/VoodooGPIO.kext   Enabled
2. VoodooI2C.kext/Contents/PlugIns/VoodooInput.kext  Enabled
3. VoodooI2C.kext                                    Enabled
4. VoodooI2CHID.kext                                 Enabled
（VoodooI2CServices.kext 不要启用）
```

### 方式二：用上游官方 kext + 我给的 Info.plist

见 `../tools/apply-kext-patches.sh`（macOS）或 `../tools/apply-kext-patches.ps1`（Windows）。

## 授权与来源

| kext | 上游 | 授权 |
|---|---|---|
| VoodooI2C / VoodooI2CHID / VoodooGPIO | [VoodooI2C/VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) | **GPL-2.0** |
| 自定义 VoodooGPIO 1.1.5 | [bafcz/VoodooGPIO](https://github.com/bafcz/VoodooGPIO) | **GPL-2.0** |
| VoodooInput | [VoodooI2C/VoodooInput](https://github.com/VoodooI2C/VoodooInput) | **GPL-2.0** |

我改的只是 **`Info.plist`（配置数据）**，没有修改任何源码；完整源码见上述上游仓库（按 GPL-2.0 要求提供来源）。
如果你要再分发这些二进制，请同时保留上游仓库链接与 GPL-2.0 声明。
