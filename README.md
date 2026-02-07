# nnez-canteen-mobile

南宁二中食堂消费 Android 客户端（Flutter + Material Design 3）。

## 本地运行

```bash
flutter pub get
flutter run
```

## GitHub Actions 构建 APK

已配置工作流：`.github/workflows/android-apk.yml`

触发方式：

1. Push 到 `main` 分支自动触发。
2. 在 GitHub 页面 `Actions -> Android APK -> Run workflow` 手动触发。

产物下载：

1. 打开本次 workflow 运行记录。
2. 在 `Artifacts` 下载 `app-release-apk`。
3. 解压得到 `app-release.apk`。
