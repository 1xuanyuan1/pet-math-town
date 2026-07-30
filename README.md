# 萌宠小镇数学冒险

面向上海小学一年级儿童的 Godot 数学小游戏。当前可玩内容包含数数配餐、
10 以内加减法，以及凑十、破十、平十和借十挑战的分步互动路线。

## 在线试玩与下载

- [浏览器在线试玩](https://1xuanyuan1.github.io/pet-math-town/)
- [B 站 Toy 在线试玩](https://www.bilibili.com/toy/pet-math-town/index.html)
- [v0.1.0 Android APK](https://github.com/1xuanyuan1/pet-math-town/releases/tag/v0.1.0)
- [隐私政策](https://1xuanyuan1.github.io/pet-math-town/privacy.html)

当前 Android 包是适合家长试玩验证的 arm64 调试签名 APK，尚不是应用商店正式签名包。
借十法暂作为教材范围待核验的扩展挑战，不标记为已经确认的一年级上册主线内容。

## Google Play 发布

项目已准备独立的 `Android Play AAB` 发布预设、仓库外上传密钥、简体中文商店资料和经过尺寸校验的商店图片。候选包固定为 `com.xuanyuan.petmathtown`、`0.1.0 (1)`、arm64、min SDK 24、target SDK 36。

`0.1.0 (1)` 已发布到有效的 Google Play 内部测试轨道；获准邮箱可通过[内部测试加入页](https://play.google.com/apps/internaltest/4701571769397259574)参与测试。下一阶段仍需至少 12 名测试者持续参加封闭测试满 14 天，才能申请正式版权限。发布资料和复现步骤见 [`docs/google-play/README.md`](docs/google-play/README.md)。

## 本地运行

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/xuanyuan/Documents/godotwork/pet-math-town --editor
```

项目默认使用 1280×720 横屏画布，优先发布 Web 与 Android APK。教学内容、语音和美术均以原创、可替换的数据与素材组织。

项目内嵌经过裁剪的 Noto Sans SC 中文字体，Web 与 Android 不依赖设备系统字体；
字体来源与 OFL 许可见 [`assets/fonts/README.md`](assets/fonts/README.md)。

实施状态和验收标准见 [`docs/implementation-plan.md`](docs/implementation-plan.md)。
