
## 今回追加した基盤

この作業で、フォークに次の基盤を追加しました。

- `shared` に `iosX64` / `iosArm64` / `iosSimulatorArm64` ターゲット
- `shared` の `iosMain` に Darwin向けKtorクライアント依存
- `PlatformInfo` の common/JVM/iOS `expect` / `actual` 境界
- `sharedUi` にAppleターゲットの登録（既存UI本体はまだjvmSharedMainのため、UI移植は未完了）
- `iosApp/` にSwiftUIホストとXcodeプロジェクト
- `.github/workflows/ios.yml` にmacOS Actionsで署名なしIPAをArtifact化する処理

現環境ではGradleタスク一覧にiOSコンパイル・Frameworkリンクタスクが生成されることを確認しました。一方、Linux SandboxではApple SDK/Xcodeがないため、iOS Frameworkの実コンパイルとXcodeアプリのビルドはGitHub ActionsのmacOSランナーでのみ検証できます。

SwiftUIホストは、現段階では移植状態を表示する最小シェルです。Android版の全機能を実装した完成版ではありません。次の実装対象は、`jvmSharedMain` からiOS対応UIを `commonMain` に分離し、AVFoundationによる再生・バックグラウンド音声・Control Center・ファイルアクセス・Keychain・OAuthを追加することです。
