# Iceraven-OLED  

[![Generic badge](https://img.shields.io/badge/arch-arm64_v8a-blue.svg)](https://en.wikipedia.org/wiki/ARM_architecture#AArch64)  

This project applies an AMOLED dark mode theme to the **arm64-v8a** version of [Iceraven Browser](https://github.com/fork-maintainers/iceraven-browser), addressing the lack of native OLED-friendly dark mode support in Firefox and its Android forks. Inspired by [Ironfox-OLEDDark](https://github.com/ArtikusHG/Ironfox-OLEDDark), this repository enhances Iceraven due to its superior customization capabilities.

### Build Prerequisites
- **Java JDK 17+** - Required for Apktool and APK signing
- **Apktool** - For decompiling and recompiling APKs
- **zipalign** - For APK alignment (Android SDK build-tools)
- **apksigner** - For APK signing (Android SDK build-tools)
- **wget** - For downloading APKs and tools
- **jq** - For parsing JSON from GitHub API

Install on Ubuntu/Debian:
```bash
sudo apt install wget apktool zipalign apksigner jq openjdk-17-jdk
```

### Features  
- Automatically builds/releases APKs when updates occur in fork-maintainers/iceraven-browser  
- OLED-optimized dark theme for reduced battery consumption  
- Enhanced visual comfort in low-light environments  

### Why Iceraven?  
While many Firefox-based browsers exist, Iceraven stands out with its:
- Extensive customization options  
- Active maintenance via fork-maintainers  
- User-driven feature implementation  

---

*Note: Requires Android device with ARM64-v8a architecture.*
