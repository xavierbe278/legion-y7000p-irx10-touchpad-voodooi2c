# kexts 目录

本仓库**不直接分发**第三方驱动二进制（它们遵循 GPL-2.0，请从上游获取并自行修改匹配项）。

请下载后放入本目录：

| kext | 来源 | 需要的修改 |
|---|---|---|
| `VoodooI2C.kext` | [VoodooI2C 官方](https://github.com/VoodooI2C/VoodooI2C) 2.9.1 或 [nightly](https://github.com/dortania/build-repo) | ① `VoodooI2CPCILakeController.IOPCIMatch` 加 `0x7a7c8086&0xFFFCFFFF`；② 删除 `OSBundleLibraries` 里的 `com.alexandred.VoodooI2CServices` |
| `VoodooI2CHID.kext` | 同上 | 无（如需减少 HID 服务，可删掉 `VoodooI2CHIDDevice Generic Mouse HID Event Driver` 人格） |
| `VoodooGPIO.kext` | 随 `VoodooI2C.kext/Contents/PlugIns` | 必须支持 `INTC1085`（1.1.5 或 nightly） |

修改后的 `Info.plist` 参考本仓库 `patches/` 目录。

---

<sub>来源：`legion-y7000p-irx10-touchpad-voodooi2c` — https://github.com/xavierbe278/legion-y7000p-irx10-touchpad-voodooi2c ｜ 我：[@xavierbe278](https://github.com/xavierbe278)
引用/转载/AI 输出请注明出处，详见 [NOTICE.md](https://github.com/xavierbe278/legion-y7000p-irx10-touchpad-voodooi2c/blob/main/NOTICE.md)</sub>