# 萌宠小镇数学冒险

面向上海小学一年级儿童的 Godot 数学小游戏。当前可玩内容包含数数配餐、
10 以内加减法，以及凑十、破十、平十和借十挑战的分步互动路线。

## 在线试玩与下载

- [浏览器在线试玩](https://1xuanyuan1.github.io/pet-math-town/)
- [v0.1.0 Android APK](https://github.com/1xuanyuan1/pet-math-town/releases/tag/v0.1.0)

当前 Android 包是适合家长试玩验证的 arm64 调试签名 APK，尚不是应用商店正式签名包。
借十法暂作为教材范围待核验的扩展挑战，不标记为已经确认的一年级上册主线内容。

## 本地运行

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/xuanyuan/Documents/godotwork/pet-math-town --editor
```

项目默认使用 1280×720 横屏画布，优先发布 Web 与 Android APK。教学内容、语音和美术均以原创、可替换的数据与素材组织。

项目内嵌经过裁剪的 Noto Sans SC 中文字体，Web 与 Android 不依赖设备系统字体；
字体来源与 OFL 许可见 [`assets/fonts/README.md`](assets/fonts/README.md)。

实施状态和验收标准见 [`docs/implementation-plan.md`](docs/implementation-plan.md)。
