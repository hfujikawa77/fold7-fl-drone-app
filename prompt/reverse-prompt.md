あなたはFlutterに精通したエンジニアです。「Drone Hinge Control」というFlutterアプリを完全に構築してください。このアプリは折りたたみ式Androidデバイス（例：Samsung Galaxy Z Fold7）のヒンジ角度を使ってMAVLink対応ドローンを制御します。ヒンジによる状態遷移、テレメトリ、マッピングを実装してください。

要件:
1. プラットフォーム
   - Flutter SDK ^3.9.2 をターゲットにする。
   - Android向け、特にフォルダブル端末（Galaxy Z Foldシリーズ）を想定。

2. コア機能
   - 端末センサーからヒンジ角度を取得・監視する。
   - ヒンジ角度に応じた状態遷移：
       - 0–30°: disarm コマンド送信。
       - 60–120°: arm コマンド送信。
       - 150–180°: Takeoff コマンド送信。
   - MAVLinkのUDP通信：
       - デフォルトエンドポイントは 127.0.0.1:14550（設定可能にする）。
       - テレメトリ（姿勢、位置、システムステータス）を解析し、UIへストリーム配信。
       - arm / disarm / takeoff / land / モード変更 / RC override などのコマンド送信。
   - OpenStreetMap（flutter_map等）を用いたリアルタイム地図。
       - ドローン位置と端末GPS位置を表示。
       - マーカーをリアルタイム更新。

3. UIレイアウト（フォルダブル最適化）
   - 端末を横開きした状態での分割レイアウト：
       - 上部約60%：インタラクティブマップ。
       - 下部約40%：テレメトリダッシュボード＋コントロールパネル。
   - テレメトリパネル：
       - 接続状態とハートビート表示。
       - 機体姿勢（ロール/ピッチ/ヨー）、高度、速度、GPS Fix、バッテリー。
       - ヒンジ角度と制御状態。
   - コントロールパネル：
       - 接続/切断、arm、disarm、takeoff、land、モード選択、RC override切替ボタン。
       - 現在のモードやフェイルセーフ状態を示すチップ。
   - UI状態管理はRiverpodなど軽量な手法を使用。

4. アーキテクチャ
   - 三層構造を採用：
       - データ/サービス層：MAVLinkサービス、ヒンジ角度サービス、位置情報サービス。
       - ドメイン/ビジネスロジック層：ヒンジイベントとMAVLinkコマンドを統合するDroneController、arm/disarm/RC overrideのステートマシン。
       - プレゼンテーション層：HomeScreen、MapView、TelemetryView、ControlPanelウィジェット。
   - ストリーム（StreamControllerやRiverpodのProvider）でリアルタイム更新。
   - サービスはストリームを公開し、コントローラが購読して状態プロバイダを更新する構造にする。

5. 追加要件
   - 位置情報許可を丁寧にリクエストし、結果に応じたハンドリングを行う。
   - エミュレータ利用時にヒンジ角度・MAVLinkのモック/フォールバックモードを用意する。
   - エラーハンドリングとユーザ通知（SnackBarやバナー等）を実装。
   - 主要クラス/サービスにドックコメント、複雑なロジックには簡潔なコメントを付与。
   - READMEに以下を記載：
       - MAVLinkエンドポイントの設定方法。
       - ヒンジ角度とドローンコマンドの対応表。
       - シミュレータ（例: Mission Planner）との接続手順。
   - ヒンジ角度ベースのステートマシンとMAVLinkコマンドルーティングに最低限のユニットテストを追加（モック可）。

成果物:
- lib/、test/、pubspec.yaml を備えたFlutterプロジェクト一式。
- エントリーポイントは lib/main.dart、Material 3 デザインを使用。
- lib/services、lib/controllers、lib/widgets、lib/features/home など明瞭な構成でソースを整理。
- `flutter analyze` と `flutter test` が成功する状態で納品すること。




Auto context