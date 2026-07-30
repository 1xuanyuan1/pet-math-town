# Google Play 发布资料

本目录保存《萌宠小镇数学冒险》Google Play 版本的可复现商店资料。密钥、密码和导出的 APK/AAB 不进入 Git。

## 发布身份

- 应用：`萌宠小镇数学冒险`
- 包名：`com.xuanyuan.petmathtown`
- 版本：`0.1.0 (1)`
- 发布预设：`Android Play AAB`
- 架构：arm64-v8a
- min SDK：24
- target SDK：36
- 上传密钥别名：`pet-math-town-upload`
- 上传证书 SHA-256：`4A:C5:3E:EE:89:7A:9F:58:95:D2:E9:1D:38:EF:AB:A6:FB:27:90:89:32:B4:D1:05:10:FB:E7:1C:14:7E:92:1E`
- 当前候选 AAB SHA-256：`7ba0eb91b5e2b5ae9c7c7956e7fbc711b10cb520886a263a7ed3923d34adeabb`
- Play App Signing：上传后在 Play Console 中启用，由 Google 管理应用签名密钥；本地密钥只作为上传密钥。

## 商店素材

`assets/` 中的交付素材：

- `app-icon-512.png`：从 `assets/icons/app_icon.svg` 导出的 512×512 PNG。
- `feature-graphic-1024x500.png`：最终 1024×500 宣传图。
- `screenshot-01-town-hub.png` 至 `screenshot-05-strategy-hub.png`：真实游戏场景的 1280×720 横屏截图。

宣传图底图使用 Bitto 明确路由生成：

- 模型：`gpt-image-2`
- 协议：`openai-images`
- 路由：explicit
- 请求尺寸：1536×1024
- 参考图：`assets/art/story/garden_intro.png`
- 精确提示词：`feature-graphic-prompt.txt`
- 原始结果：`assets/feature-graphic-bitto-source.png`

生成后使用项目内的 Noto Sans SC 字体本地叠加准确中文标题并裁切：

```bash
swift tools/compose_play_feature_graphic.swift \
  docs/google-play/assets/feature-graphic-bitto-source.png \
  assets/fonts/NotoSansSC-GameSubset.ttf \
  docs/google-play/assets/feature-graphic-1024x500.png
```

## 签名和导出

上传密钥保存在仓库外：

`/Users/xuanyuan/Library/Application Support/Godot/keystores/pet-math-town-upload.jks`

密码存储在 macOS 钥匙串服务 `codex.pet-math-town.google-play-upload` 中。导出前，把密钥路径、别名和钥匙串密码作为临时环境变量传给 `tools/configure_play_export_credentials.gd`；该脚本只写入被忽略的 `.godot/export_credentials.cfg`。不要把密码写入命令记录、文档或 Git。

```bash
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --path /Users/xuanyuan/Documents/godotwork/pet-math-town \
  --export-release "Android Play AAB" \
  build/android/pet-math-town-v0.1.0-release.aab
```

当前候选包已通过 Godot 4.7 导入、1753 项自动检查、bundletool 1.18.1 校验、JAR 签名校验与 ZIP 完整性检查。Manifest 已确认包名、版本、min/target SDK、游戏类别、标准 LAUNCHER 入口及无 HOME 入口；原生库只有 `arm64-v8a`，应用资源路径与凭据扫描无异常。

## 发布顺序

1. 上传已签名 AAB 到内部测试，使用加入链接完成安装和启动验收，并检查预发布报告。
2. 收到至少 12 个测试者的 Google 邮箱后，创建封闭测试；至少 12 人持续选择加入满 14 天。
3. 根据真实测试反馈申请正式版权限。
4. 权限获批后，将已验证版本推广到生产。测试期间如修改应用，必须递增版本代码并重新验证。

内部测试重点验证横屏启动、触控、中文字体、语音、离线运行、各路线进入和本地进度保存。
