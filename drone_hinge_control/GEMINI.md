# GEMINI.md - Drone Hinge Control Application

## アプリケーション概要

**Drone Hinge Control** は、折りたたみデバイス（Samsung Galaxy Z Fold7をターゲット）のヒンジ角度を利用してMAVLink対応ドローンを操作する革新的なFlutterアプリケーションです。従来のドローン操作インターフェースとは異なり、デバイスの物理的な形状変化をドローンの状態制御に直接結びつけることで、直感的で新しい操縦体験を提供します。

## アプリケーションの目的

### 主要目標

1. **革新的な操作体験**: 折りたたみデバイスのヒンジ角度という新しい入力方法でドローンを制御
2. **実用的な機能統合**: 地図表示、テレメトリモニタリング、手動操作など、ドローン操縦に必要な機能を統合
3. **教育・実験プラットフォーム**: MAVLinkプロトコル、Flutterの高度な機能、折りたたみデバイス対応の学習材料
4. **Mission Planner互換性**: シミュレータ環境での検証と開発を可能にする

### 対象ユーザー

- ドローン愛好家、開発者
- 折りたたみデバイスの新しい利用方法を探求する研究者
- MAVLinkプロトコルの学習者
- Flutter開発の実践例を求める開発者

## 技術的実装詳細

### アーキテクチャパターン

本アプリケーションは**レイヤードアーキテクチャ（3層構造）**を採用しています：

```
┌──────────────────────────────────────────────┐
│ Presentation Layer (プレゼンテーション層)    │
│ ・UI表示とユーザー入力の処理                 │
│ ・Widgets: HomeScreen, MapView, TelemetryView│
└────────────┬─────────────────────────────────┘
             │ ユーザーアクション
             ▼
┌──────────────────────────────────────────────┐
│ Domain Layer (ビジネスロジック層)            │
│ ・アプリケーションロジックの中核             │
│ ・Controllers: DroneController               │
│ ・ヒンジ角度→ドローンコマンド変換            │
└────────────┬─────────────────────────────────┘
             │ サービス呼び出し
             ▼
┌──────────────────────────────────────────────┐
│ Data/Service Layer (データ/サービス層)      │
│ ・外部とのやり取り（センサー、通信）         │
│ ・Services: MavlinkService, HingeAngleService│
│            LocationService                    │
└──────────────────────────────────────────────┘
```

### コンポーネント詳細

#### 1. Data/Service Layer（データ/サービス層）

**HingeAngleService** (`lib/data/services/hinge_angle_service.dart`)
- **役割**: 折りたたみデバイスのヒンジ角度を取得
- **技術**: Microsoft `dual_screen`パッケージ利用
- **出力**: `Stream<double>` - リアルタイムのヒンジ角度（度数）
- **特徴**: エラーハンドリング、デバイス非対応時の対応

**MavlinkService** (`lib/data/services/mavlink_service.dart`)
- **役割**: MAVLinkプロトコルによるドローンとの通信
- **技術**: UDPソケット、`dart_mavlink`パッケージ
- **機能**:
  - ハートビート送信（接続維持）
  - コマンド送信（アーム/ディスアーム、離着陸、モード変更）
  - テレメトリ受信（位置、姿勢情報）
- **ストリーム**:
  - `inputStream`: 全MAVLinkメッセージ
  - `positionStream`: GPS位置情報（GLOBAL_POSITION_INT）
  - `attitudeStream`: 姿勢情報（ATTITUDE）
- **特徴**: メッセージタイプ別のストリーム分離、リソース管理

**LocationService** (`lib/data/services/location_service.dart`)
- **役割**: デバイスのGPS位置取得
- **技術**: `geolocator`パッケージ
- **機能**:
  - 位置情報ストリーム提供
  - 自動パーミッション要求
  - エラーハンドリング
- **出力**: `Stream<LatLng>` - デバイスの緯度経度

**RawDatagramSocketService** (`lib/data/services/raw_datagram_socket_service.dart`)
- **役割**: UDPソケット操作の抽象化
- **目的**: テスタビリティ向上、依存性注入の実現
- **技術**: Dartの`RawDatagramSocket`ラッパー

#### 2. Domain Layer（ビジネスロジック層）

**DroneController** (`lib/domain/controllers/drone_controller.dart`)
- **役割**: アプリケーションの中核制御ロジック
- **主要機能**:
  1. ヒンジ角度の監視と解釈
     ```dart
     0-30度    → Disarmコマンド
     60-120度  → Armコマンド
     150-180度 → RC Overrideコマンド
     ```
  2. 手動操作コマンド実行
     - 離陸（Takeoff）
     - 着陸（Land）
     - フライトモード変更（GUIDED, STABILIZE, RTL等）
  3. 状態管理
     - 重複コマンド防止
     - 現在のドローン状態追跡

- **設計パターン**:
  - Observer Pattern（ストリーム監視）
  - State Pattern（ドローン状態管理）

**DroneState** (enum in `drone_controller.dart`)
```dart
enum DroneState {
  unknown,     // 不明な状態
  disarmed,    // ディスアーム状態
  armed,       // アーム状態
  rcOverride   // RC Override状態
}
```

#### 3. Presentation Layer（プレゼンテーション層）

**HomeScreen** (`lib/presentation/screens/home_screen.dart`)
- **役割**: メイン画面、全コンポーネントの統合
- **レイアウト設計**:
  - 上部60%: MapView（地図表示）
  - 下部40%: TelemetryView + 操作パネル（スクロール可能）
- **状態管理**:
  - 複数のストリームサブスクリプション
  - リアルタイムUI更新
  - 適切なリソースクリーンアップ（dispose）
- **UI セクション**:
  1. Connection: MAVLink接続/切断
  2. Monitoring: ヒンジ角度監視の開始/停止
  3. Status: 現在のヒンジ角度とドローン状態
  4. Manual Controls: 手動操作ボタン
  5. Messages: 受信MAVLinkメッセージログ

**MapView** (`lib/presentation/widgets/map_view.dart`)
- **役割**: ドローンとデバイスの位置を地図上に表示
- **技術**: `flutter_map` + OpenStreetMap タイル
- **機能**:
  - ドローン位置マーカー（赤色飛行機アイコン）
  - デバイス位置マーカー（青色ピンアイコン）
  - 自動センタリング（データがある方に合わせる）
  - MAVLink座標変換（int32 × 10^7 → 度数）
- **デフォルト中心**: 東京（35.6812, 139.7671）

**TelemetryView** (`lib/presentation/widgets/telemetry_view.dart`)
- **役割**: ドローンのテレメトリデータを見やすく表示
- **表示項目**:
  - **姿勢 (Attitude)**:
    - Roll, Pitch, Yaw（ラジアン→度数変換）
  - **位置 (Position)**:
    - 緯度、経度（6桁精度）
    - 相対高度、MSL高度（メートル）
    - ヘディング（度数）
- **UI特徴**:
  - アイコン付きデータ行
  - 等幅フォントでの数値表示
  - データなし時の適切なメッセージ

### データフローの詳細

#### 1. ヒンジ角度ベースの自動制御フロー

```
[物理デバイス]
    ↓ ヒンジ角度変化
[dual_screen パッケージ]
    ↓ センサーデータ
[HingeAngleService]
    ↓ Stream<double>
[DroneController] ← startMonitoring() で監視開始
    ↓ 角度判定 & コマンド生成
[MavlinkService]
    ↓ UDP通信
[ドローン/シミュレーター]
```

#### 2. テレメトリ受信と表示フロー

```
[ドローン/シミュレーター]
    ↓ MAVLink メッセージ (UDP)
[MavlinkService]
    ├→ positionStream (GlobalPositionInt)
    └→ attitudeStream (Attitude)
         ↓
[HomeScreen] - ストリーム監視
    ├→ [MapView] ← ドローン位置更新
    └→ [TelemetryView] ← 姿勢・位置データ更新
```

#### 3. 手動操作フロー

```
[ユーザー] ボタンタップ
    ↓
[HomeScreen] onPressed
    ↓
[DroneController] メソッド呼び出し
    (takeoff(), land(), setMode())
    ↓
[MavlinkService] MAVLinkコマンド送信
    (COMMAND_LONG)
    ↓
[ドローン/シミュレーター]
```

### MAVLink プロトコル実装

#### 使用するメッセージタイプ

1. **Heartbeat** (ID: 0)
   - 目的: 接続維持、システム状態通知
   - 送信頻度: 1 Hz
   - パラメータ: システムタイプ、オートパイロット、ベースモード

2. **CommandLong** (ID: 76)
   - 目的: コマンド送信
   - 使用コマンド:
     - `MAV_CMD_COMPONENT_ARM_DISARM` (400): アーム/ディスアーム
     - `MAV_CMD_NAV_TAKEOFF` (22): 離陸
     - `MAV_CMD_NAV_LAND` (21): 着陸
     - `MAV_CMD_DO_SET_MODE` (176): モード変更

3. **RcChannelsOverride** (ID: 70)
   - 目的: RCチャンネル値の直接制御
   - 実装: 18チャンネル全てに値を指定
   - トリガー: ヒンジ角度 150-180度

4. **GlobalPositionInt** (ID: 33) - 受信のみ
   - 内容: GPS位置、高度、速度
   - 使用: MapView での位置表示、TelemetryView での数値表示
   - 座標形式: int32 (度 × 10^7)

5. **Attitude** (ID: 30) - 受信のみ
   - 内容: Roll, Pitch, Yaw（ラジアン）
   - 使用: TelemetryView での姿勢表示
   - 変換: ラジアン → 度数（表示用）

#### フライトモードマッピング（ArduCopter）

```dart
final modeMap = {
  'STABILIZE': 0,   // 安定化モード
  'ACRO': 1,        // アクロバットモード
  'ALT_HOLD': 2,    // 高度保持
  'AUTO': 3,        // 自動航行
  'GUIDED': 4,      // ガイドモード
  'LOITER': 5,      // 旋回
  'RTL': 6,         // Return to Launch
  'CIRCLE': 7,      // 円旋回
  'LAND': 9,        // 着陸
  // ... その他
};
```

### 座標系と単位変換

#### MAVLink 座標形式
```
緯度/経度: int32 型
値 = 度数 × 10,000,000 (10^7)
例: 35.6812° → 356,812,000
```

#### アプリ内変換
```dart
// MAVLink → 表示用
double lat = position.lat / 1e7;  // int32 → double (度)
double lon = position.lon / 1e7;

// 高度
double altMSL = position.alt / 1000.0;        // mm → m
double altRel = position.relativeAlt / 1000.0; // mm → m

// 姿勢
double rollDeg = attitude.roll * 180.0 / pi;   // rad → deg
double pitchDeg = attitude.pitch * 180.0 / pi;
double yawDeg = attitude.yaw * 180.0 / pi;
```

### 状態管理とライフサイクル

#### ストリーム管理

アプリケーション全体で複数のストリームを管理：

```dart
// HomeScreen内
StreamSubscription? _mavlinkSubscription;    // 全MAVLinkメッセージ
StreamSubscription? _positionSubscription;   // GPS位置
StreamSubscription? _attitudeSubscription;   // 姿勢
StreamSubscription? _locationSubscription;   // デバイス位置

@override
void dispose() {
  // 全てのサブスクリプションをキャンセル
  _mavlinkSubscription?.cancel();
  _positionSubscription?.cancel();
  _attitudeSubscription?.cancel();
  _locationSubscription?.cancel();

  // サービスのクリーンアップ
  _mavlinkService.dispose();
  _locationService.dispose();
  _droneController.dispose();

  super.dispose();
}
```

#### リソース管理のベストプラクティス

1. **StreamController**: broadcastで複数リスナー対応
2. **dispose()**: 各サービスで適切にリソース解放
3. **mounted チェック**: 非同期操作後のウィジェット存在確認

### パーミッション処理

#### Android Manifest設定
```xml
<!-- 位置情報 -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- ネットワーク -->
<uses-permission android:name="android.permission.INTERNET" />
```

#### ランタイム パーミッション処理
```dart
// LocationService内で自動処理
1. サービス有効チェック (isLocationServiceEnabled)
2. パーミッション確認 (checkPermission)
3. 必要に応じて要求 (requestPermission)
4. 拒否時のエラーハンドリング
```

### テスト戦略

#### ユニットテストの構成

**HingeAngleService テスト**
- ストリーム動作検証
- エラーハンドリング確認

**MavlinkService テスト**
- モックソケットを使用した通信テスト
- メッセージパース検証
- 接続/切断ロジック確認

**DroneController テスト (13テストケース)**
1. 初期状態検証
2. ヒンジ角度範囲別の動作確認（Disarm, Arm, RC Override）
3. 状態変化時のコマンド送信確認
4. 同一状態での重複送信防止
5. 手動操作メソッド（takeoff, land, setMode）検証
6. 監視開始/停止の動作確認

#### モッキング戦略

```dart
// Mocktail使用
class MockMavlinkService extends Mock implements MavlinkService {}
class MockHingeAngleService extends Mock implements HingeAngleService {}

// Fallback値登録（カスタム型用）
registerFallbackValue(FakeMavlinkFrame());
```

### エラーハンドリング

#### 階層別のエラー処理

**Service層**
- 例外スロー: `throw Exception('...')`
- エラーログ出力: `print()` (開発時)

**Controller層**
- ストリームエラーハンドリング
- 状態の適切なリセット

**UI層**
- SnackBarでユーザーへの通知
- `snapshot.hasError` での表示切り替え

## ファイルレイアウトと組織化

### ディレクトリ構造の理由

```
lib/
├── main.dart                    # エントリーポイント、MyApp widget
├── data/                        # 外部データソース層
│   ├── services/               # 各種サービス実装
│   │   ├── mavlink_service.dart
│   │   ├── hinge_angle_service.dart
│   │   ├── location_service.dart
│   │   └── raw_datagram_socket_service.dart
│   └── models/                 # データモデル
│       └── drone_state.dart   # (現在はenum形式でcontroller内)
├── domain/                     # ビジネスロジック層
│   ├── controllers/           # アプリケーションロジック
│   │   └── drone_controller.dart
│   └── notifiers/             # 状態通知（Riverpod用、将来拡張）
│       └── ui_state_notifier.dart
└── presentation/              # UI層
    ├── screens/              # 画面単位のウィジェット
    │   └── home_screen.dart
    └── widgets/              # 再利用可能なウィジェット
        ├── map_view.dart
        └── telemetry_view.dart
```

### レイヤー間の依存関係ルール

```
Presentation → Domain → Data
     ↓           ↓        ↓
   UI のみ     ロジック   外部I/O

依存の方向: 外側 → 内側 (Clean Architecture原則)
```

## 開発の経緯と学び

### Phase別開発プロセス

**Phase 1**: プロジェクトセットアップ
- 基本構造作成、依存関係定義

**Phase 2**: ヒンジ角度サービス
- `dual_screen`パッケージの統合
- ストリームベースAPI設計

**Phase 3**: MAVLink通信
- UDPソケット実装
- テスタビリティのための抽象化層追加

**Phase 4**: ドローン制御ロジック
- ヒンジ角度→コマンドマッピング実装
- 状態管理の実装

**Phase 5**: 地図とテレメトリUI
- flutter_map統合
- リアルタイムデータ表示
- 位置情報サービス追加

### 技術的な発見

1. **ストリームアーキテクチャの有効性**
   - 複数のデータソースを統一的に扱える
   - リアルタイム更新が自然に実装できる

2. **テスタビリティの重要性**
   - RawDatagramSocketServiceの抽象化
   - 依存性注入による柔軟なテスト

3. **座標系変換の注意点**
   - MAVLinkとFlutter間の単位変換
   - 精度維持の重要性

4. **リソース管理**
   - dispose()の徹底
   - メモリリーク防止

## 将来の拡張可能性

### 技術的拡張

1. **Riverpod統合**: 現在の手動状態管理をRiverpodで置き換え
2. **バッテリーモニタリング**: SYS_STATUSメッセージ解析
3. **ウェイポイント機能**: MISSION_ITEMメッセージでの経路設定
4. **フライトログ**: テレメトリデータの記録と再生

### UI/UX改善

1. **デュアルスクリーン対応**: 左右画面で異なる情報表示
2. **カスタムテーマ**: ダークモード、カラースキーム
3. **設定画面**: MAVLink接続設定、閾値調整
4. **多言語対応**: 国際化対応

### 機能追加

1. **複数ドローン対応**: システムID別管理
2. **カメラフィード**: VIDEO_STREAM統合
3. **ジオフェンス**: 飛行制限エリア設定
4. **自動操縦**: 簡易的なミッション実行

## まとめ

Drone Hinge Controlは、折りたたみデバイスの物理的特性を活用した革新的なドローン制御アプリケーションです。クリーンアーキテクチャとストリームベースの設計により、保守性と拡張性を確保しながら、MAVLinkプロトコルの完全な実装を実現しています。

このアプリケーションは、技術実験とプロトタイプとして、新しいインタラクション方法の可能性を示すとともに、Flutter開発のベストプラクティスと高度な機能の実装例として機能します。

---

**開発環境**: Flutter 3.9.2+, Dart 3.0+
**対象プラットフォーム**: Android (折りたたみデバイス)
**テスト環境**: Mission Planner Simulator, ArduCopter
**開発期間**: 2025年11月5日
**コード行数**: 約2,000行（コメント含む）

🤖 Generated with [Claude Code](https://claude.com/claude-code)
