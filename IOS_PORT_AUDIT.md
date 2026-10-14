# BitChord iOS移植監査レポート

作成日: 2026-10-14  
対象: `kushagrasinghx/BitChord` (`main`)  
フォーク: https://github.com/386612/BitChord

## 現時点の結論

この作業で、Kotlin MultiplatformのiOSターゲット、iOS側の共有API、SwiftUIホスト、署名なしIPAを生成するGitHub Actionsの足場を追加しました。ただし、これは**完全機能版のiOS移植ではありません**。SwiftUIホストは現在、移植基盤が動作することを確認するための最小シェルです。

元のAndroid UIの大部分は`jvmSharedMain`にあり、再生機能はAndroid Media3/JNI/NDKに依存しています。そのため、Android版と同等の検索、再生、バックグラウンド再生、ダウンロード、ログイン、連携機能をiOSで動かすには追加実装が必要です。

## 今回追加したもの

- `shared`に`iosX64`、`iosArm64`、`iosSimulatorArm64`ターゲット
- `shared`の`iosMain`にKtor Darwinクライアント依存
- `PlatformInfo`のcommon/JVM/iOS `expect` / `actual`境界
- `sharedUi`へのAppleターゲット登録
- `iosApp/BitChordIOS.xcodeproj`とSwiftUIエントリポイント
- `.github/workflows/ios.yml`によるmacOS Actions上の署名なしIPA生成

## iOSで未実装の主要領域

### 再生・バックグラウンド

Android Media3/ExoPlayer、AudioFocus、Foreground Serviceを、AVFoundation、AVAudioSession、MPNowPlayingInfoCenter、MPRemoteCommandCenter、Background Audioへ置き換える必要があります。クロスフェード、ギャップレス再生、速度変更、イコライザ、通知・ロック画面操作もiOS APIに合わせて再設計します。

### ネイティブ音声

Android JNIとNDK向けFFmpegを、Apple向けXCFrameworkまたはSwift/Objective-Cブリッジに置き換える必要があります。ALAC、FLAC、AC-3等のコーデック対応と、端末・シミュレータ双方のarm64構成を検証します。

### UIとOS連携

既存のCompose UIを`jvmSharedMain`からiOSで利用可能な`commonMain`へ段階的に移動し、Status Bar、Sheet、戻る操作、Haptics、Blur、ファイル選択などのiOS実装を追加します。オフライン保存、Keychain、OAuth redirect、通知、URL scheme、Info.plist、権限も対応が必要です。

### 配布

今回のActionsは`CODE_SIGNING_ALLOWED=NO`で署名なしIPAをArtifactとして作成します。AltStore/Sideloadly等でユーザーのApple Accountにより再署名してからインストールする方式です。Actionsから直接インストール可能なIPAを作る場合は、Apple Developerの証明書、秘密鍵、Provisioning ProfileをGitHub Secretsへ登録する必要があります。

## 検証結果

Linux Sandboxでは、Gradleタスク一覧にiOSコンパイル・Frameworkリンクタスクが生成されることを確認しました。`xcodebuild`とApple SDKはLinuxにないため、iOS Frameworkの実コンパイルとXcodeアプリのビルドはmacOSのGitHub Actionsで検証します。

既存JVMテストは、Sandboxに入っているJava 21がJavaコンパイラ機能を提供しないため実行時に停止しました。これは今回のiOS変更によるコンパイルエラーではなく、実行環境のJDK構成によるものです。

## 次の実装順序

1. iOS用の共通UIを`commonMain`へ分離
2. AVFoundation再生エンジンとバックグラウンド音声を実装
3. iOS用のファイル、Keychain、OAuth、通知、URL schemeを実装
4. 外部サービスとオフラインダウンロードをiOSで接続
5. macOS Actionsでシミュレータ・実機向けビルドを検証
6. 必要に応じてAltStore/Sideloadly用の署名手順を整備

このレポートは、未実装機能や未検証のIPAを「完全動作済み」と誤認しないための状態記録です。
