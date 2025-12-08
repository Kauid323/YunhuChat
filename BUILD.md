# 构建说明

## Android 构建配置

本项目已配置为只编译 **arm64** 和 **arm32** 架构的 APK。

### 构建命令

```bash
# 构建 APK（只包含 arm64 和 arm32）
flutter build apk --split-per-abi

# 构建 App Bundle（推荐用于 Google Play）
flutter build appbundle

# 构建特定架构
flutter build apk --target-platform android-arm64
flutter build apk --target-platform android-arm
```

### 架构说明

- **armeabi-v7a** (arm32): 32位 ARM 架构，兼容大部分旧设备
- **arm64-v8a** (arm64): 64位 ARM 架构，现代设备标准

### 配置位置

配置在 `android/app/build.gradle` 文件中：

```gradle
splits {
    abi {
        enable true
        reset()
        include 'armeabi-v7a', 'arm64-v8a'
        universalApk false
    }
}
```

### 注意事项

- `universalApk false` 表示不生成包含所有架构的通用 APK
- 每个架构会生成独立的 APK 文件
- 这样可以减小 APK 体积，提高下载和安装速度

