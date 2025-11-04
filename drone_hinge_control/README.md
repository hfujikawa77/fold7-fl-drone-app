# Drone Hinge Control

A Flutter application that enables intuitive drone control using the hinge angle of foldable devices like the Samsung Galaxy Z Fold7. This app communicates with MAVLink-compatible drones and provides real-time telemetry, map visualization, and innovative hinge-based control.

## Features

### Core Functionality

- **Hinge Angle-Based Control**: Control drone states using your foldable device's hinge angle
  - 0-30°: Disarm
  - 60-120°: Arm
  - 150-180°: Takeoff
- **MAVLink Communication**: Full-featured communication with MAVLink-compatible drones
- **Real-Time Map Display**: Interactive map showing drone and device positions
- **Telemetry Dashboard**: Live attitude and position data display
- **Manual Controls**: Traditional takeoff, landing, and flight mode controls

### User Interface

- **Split-Screen Layout**: Optimized for foldable devices
  - Top 60%: Interactive map with drone and device markers
  - Bottom 40%: Telemetry data and control panel
- **Real-Time Updates**: Stream-based architecture for instantaneous data updates
- **Clean Organization**: Intuitive sections for connection, monitoring, status, and controls

## Architecture

This application follows a clean layered architecture:

```
┌─────────────────────────────────────┐
│   UI Layer (Presentation)           │
│   - HomeScreen                       │
│   - MapView, TelemetryView           │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│   Business Logic Layer (Domain)     │
│   - DroneController                  │
│   - UIStateNotifier                  │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│   Data/Service Layer                 │
│   - MavlinkService                   │
│   - HingeAngleService                │
│   - LocationService                  │
└─────────────────────────────────────┘
```

### Key Components

**Services (Data Layer)**
- `MavlinkService`: Handles UDP communication with drones, message parsing, and telemetry streams
- `HingeAngleService`: Provides real-time hinge angle data from the device
- `LocationService`: Manages device GPS location with permission handling

**Controllers (Business Logic)**
- `DroneController`: Coordinates hinge angle monitoring and drone command execution
- State management for arm/disarm/takeoff based on hinge angle thresholds

**UI Components (Presentation)**
- `HomeScreen`: Main application interface with integrated map and controls
- `MapView`: Interactive map using flutter_map with OpenStreetMap tiles
- `TelemetryView`: Formatted display of attitude and position data

## Getting Started

### Prerequisites

- Flutter SDK (^3.9.2)
- Android device or emulator (preferably a foldable device)
- Mission Planner or MAVLink-compatible drone simulator

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd drone_hinge_control
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

### Configuration

**MAVLink Connection**
- Default connection: `127.0.0.1:14550` (Mission Planner simulator)
- Modify in `MavlinkService.connect()` for different targets

**Location Permissions**
- The app will automatically request location permissions on first launch
- Grant `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` permissions

### Mission Planner ↔ Device Connection

- **Network Requirements**
  - Connect the Samsung Galaxy Z Fold7 (or other Android test device) and the Mission Planner PC to the same Wi‑Fi network.
  - On the device, open *Settings → Connections → Wi‑Fi → [Current network]* and note the IPv4 address (e.g. `192.168.3.178`).

- **Mission Planner Configuration**
  1. Press `Ctrl + F` in Mission Planner, choose **MAVLink**, and add two rows in the Serial/Mavlink window:
     - `UDP / Outbound / Port 14551 / Host <device-ip>` → click **Go**.  
       The Flutter app listens on UDP `14551` for telemetry/heartbeat streams.
     - `UDP / Inbound / Port 14550 / Host <device-ip>` → click **Go**.  
       Commands from the app are transmitted to UDP `14550`; this inbound rule lets Mission Planner accept them.
  2. Approve any Windows firewall prompts so UDP `14550` and `14551` are allowed.
  3. Open **MAVLink Inspector**. When the app connects you should see a new entry (system ID `201`, component `191`) alongside Mission Planner.

- **Device Steps**
  - Launch the Flutter app and tap **Connect MAVLink**. The debug log shows:  
    `MAVLink GCS identity: systemId=201 componentId=191` and `Listening for MAVLink on 0.0.0.0:14551`.
  - Tap **Start Monitoring** for hinge-angle control or trigger manual buttons (GUIDED/RTL/Takeoff) to confirm that commands are accepted.

## Usage

### Basic Workflow

1. **Connect to Drone**
   - Tap "Connect MAVLink" to establish connection with the simulator/drone
   - Wait for "Connected" status

2. **Start Monitoring**
   - Tap "Start Monitoring" to enable hinge angle-based control
   - Adjust your device's hinge angle to control drone state

3. **Monitor Telemetry**
   - View real-time drone position on the map
   - Check attitude (Roll, Pitch, Yaw) in the telemetry panel
   - Monitor altitude, heading, and GPS coordinates

4. **Manual Control**
   - Use buttons for manual takeoff/landing
   - Switch flight modes (GUIDED, STABILIZE, RTL)
   - Send heartbeat messages manually if needed

### Hinge Angle Control

| Hinge Angle | Drone Action | Description |
|------------|--------------|-------------|
| 0-30° | Disarm | Safely disarm the drone |
| 60-120° | Arm | Arm the drone for flight |
| 150-180° | Takeoff | Initiate automated takeoff sequence |

## Testing

### Unit Tests

Run all unit tests:
```bash
flutter test
```

The test suite includes:
- `HingeAngleService` tests
- `MavlinkService` tests with mocked sockets
- `DroneController` tests with 13 test cases

### Code Quality

Check code quality:
```bash
# Apply automatic fixes
dart fix --apply

# Analyze code
flutter analyze

# Format code
dart format .
```

## Dependencies

### Core Dependencies
- `flutter`: SDK for cross-platform development
- `dart_mavlink` (^0.1.0): MAVLink protocol implementation
- `dual_screen` (^1.0.4): Hinge angle detection for foldable devices
- `flutter_map` (^8.2.2): Interactive map component
- `latlong2` (^0.9.1): Geographic coordinate utilities
- `geolocator` (^13.0.2): Device location services

### Development Dependencies
- `flutter_test`: Testing framework
- `mocktail` (^1.0.4): Mocking library for tests
- `build_runner` (^2.9.0): Code generation
- `flutter_lints` (^5.0.0): Linting rules

## Project Structure

```
drone_hinge_control/
├── lib/
│   ├── main.dart                      # Application entry point
│   ├── data/                          # Data/Service Layer
│   │   ├── services/
│   │   │   ├── mavlink_service.dart   # MAVLink communication
│   │   │   ├── hinge_angle_service.dart # Hinge angle monitoring
│   │   │   ├── location_service.dart  # GPS location
│   │   │   └── raw_datagram_socket_service.dart # UDP abstraction
│   │   └── models/
│   │       └── drone_state.dart       # Data models
│   ├── domain/                        # Business Logic Layer
│   │   ├── controllers/
│   │   │   └── drone_controller.dart  # Main controller
│   │   └── notifiers/
│   │       └── ui_state_notifier.dart # UI state management
│   └── presentation/                  # UI Layer
│       ├── screens/
│       │   └── home_screen.dart       # Main screen
│       └── widgets/
│           ├── map_view.dart          # Map component
│           └── telemetry_view.dart    # Telemetry display
├── test/                              # Unit tests
├── android/                           # Android-specific configuration
├── DESIGN.md                          # Design documentation (Japanese)
├── IMPLEMENTATION.md                  # Implementation journal (Japanese)
└── pubspec.yaml                       # Project dependencies
```

## Technical Details

### MAVLink Communication
- Uses UDP sockets for communication
- Supports ArduPilot MAVLink dialect
- Implements heartbeat, command_long, and RC override messages
- Parses position (GLOBAL_POSITION_INT) and attitude (ATTITUDE) telemetry

### Coordinate Systems
- MAVLink coordinates: int32 format (degrees × 10^7)
- Display coordinates: Decimal degrees
- Automatic conversion in MapView component

### State Management
- Stream-based reactive architecture
- Multiple broadcast streams for different data types
- Proper resource cleanup with dispose methods

### Permission Handling
- Runtime location permission requests
- Background location support for Android 10+
- Internet permission for MAVLink communication

## Development Notes

### Testing with Mission Planner

1. Start Mission Planner
2. Go to Simulation tab
3. Select "Multirotor" and start simulation
4. Note the UDP port (typically 14550)
5. Run this app and connect to `127.0.0.1:14550`

### Debugging Tips

- Check "Received MAVLink Messages" section for communication status
- Monitor console output for print statements (connection events, commands)
- Use `flutter analyze` to identify potential issues
- MAVLink message types are logged in real-time

### Known Limitations

- Hinge angle detection requires physical foldable device (emulator support limited)
- Location services require GPS-enabled device
- MAVLink communication tested primarily with Mission Planner simulator
- Print statements in production code (info-level warnings)

## Roadmap

### Completed Features ✓
- Phase 1: Project setup and structure
- Phase 2: Hinge angle service implementation
- Phase 3: MAVLink communication
- Phase 4: Drone control logic
- Phase 5: Map and telemetry UI

### Future Enhancements
- Enhanced RC override with configurable channel values
- Waypoint mission planning
- Flight path recording and replay
- Battery level monitoring
- Multiple drone support
- Custom map tile servers
- Offline map caching

## Contributing

This is an educational/experimental project. Contributions, suggestions, and issue reports are welcome.

## License

This project is provided as-is for educational and experimental purposes.

## Acknowledgments

- **Microsoft** for the `dual_screen` package
- **ArduPilot** community for MAVLink protocol
- **flutter_map** contributors for the mapping solution
- **Mission Planner** for simulation capabilities

## Contact & Support

For questions, issues, or suggestions:
- Review the DESIGN.md for architecture details
- Check IMPLEMENTATION.md for development journal
- Submit issues through the project repository

---

**Target Device:** Samsung Galaxy Z Fold7
**Development Date:** November 2025
**Flutter Version:** 3.9.2+
**Platform:** Android

🤖 Generated with assistance from Claude Code
# Drone Hinge Control

折りたたみ端末（Samsung Galaxy Z Fold7 想定）のヒンジ角を使って MAVLink 対応ドローンを直感的に操作する Flutter アプリです。ヒンジ角に応じたアーム／ディスアームや Takeoff に加えて、リアルタイムのテレメトリ表示、地図上での位置追跡、手動コマンド送信をサポートします。

## 特長

### 基本機能

- **ヒンジ角連動制御**  
  - 0〜30°: ディスアーム  
  - 60〜120°: アーム  
  - 150〜180°: Takeoff
- **MAVLink 通信**: ArduPilot 方言に対応した UDP 通信とメッセージ解析
- **リアルタイム地図表示**: ドローン位置、端末位置、移動軌跡を同時に描画
- **テレメトリダッシュボード**: 姿勢・位置・高度・ヘディングをライブ表示
- **手動操作**: アーム／ディスアーム、GUIDED/AUTO/RTL などのモード切替、離着陸、ハートビート送信

### ユーザーインターフェース

- **分割レイアウト**: 上段 60 % に地図、下段 40 % にテレメトリと操作パネルを配置
- **リアルタイム更新**: Stream ベースで UI に即時反映
- **オートパン切り替え**: チェックボックスでドローン中心表示の ON/OFF を切替
- **ログ表示**: 直近の受信 MAVLink メッセージをリストで確認

## アーキテクチャ

```
Presentation Layer
  └─ HomeScreen / MapView / TelemetryView
Domain Layer
  └─ DroneController / UIStateNotifier
Data & Service Layer
  └─ MavlinkService / HingeAngleService / LocationService / RawDatagramSocketService
```

### 主なコンポーネント

**サービス（Data Layer）**
- `MavlinkService`: UDP ソケットで MAVLink メッセージを送受信し、テレメトリをストリーム配信
- `HingeAngleService`: `dual_screen` パッケージを通じてヒンジ角ストリームを提供
- `LocationService`: 端末 GPS の現在地と連続更新を管理

**ビジネスロジック（Domain Layer）**
- `DroneController`: ヒンジ角に応じた状態遷移と MAVLink コマンド送信、手動操作 API を提供
- `UIStateNotifier`（将来拡張）: UI 状態の集中管理を想定

**UI（Presentation Layer）**
- `HomeScreen`: 画面全体の状態管理とサービス初期化
- `MapView`: `flutter_map` でドローン・端末位置と軌跡を描画、オートパン対応
- `TelemetryView`: 姿勢・位置・高度などを単位変換しつつ整形表示

## セットアップ

### 前提条件

- Flutter SDK 3.9.2 以降
- Android 実機またはエミュレータ（折りたたみ端末が望ましい）
- Mission Planner など MAVLink 対応ドローンシミュレータ

### インストール手順

```bash
git clone <repository-url>
cd drone_hinge_control
flutter pub get
```

実行:

```bash
flutter run
```

### 設定

**MAVLink 接続**  
- 既定は `127.0.0.1:14550`（Mission Planner シミュレータ）  
- 他の IP/ポートを使う場合はアプリの接続ボタンを押す前に `MavlinkService.connect()` の呼び出し引数を変更するか、UI から接続先を調整してください。

**位置情報パーミッション**  
- 初回起動時に `ACCESS_FINE_LOCATION` と `ACCESS_COARSE_LOCATION` を要求します。端末で許可してください。

### Mission Planner ↔ デバイス接続

- **ネットワーク準備**
  - Galaxy Z Fold7 と Mission Planner を実行する PC を同一 Wi-Fi に接続します。
  - 端末の *設定 → 接続 → Wi-Fi → [使用中のネットワーク]* で IPv4 アドレス（例: `192.168.3.178`）をメモします。

- **Mission Planner の設定**
  1. Mission Planner で `Ctrl + F` → **MAVLink** を開き、次の 2 行を追加して **Go** を押します。  
     - `UDP / Outbound / Port 14551 / Host <端末IP>` … アプリは UDP 14551 でテレメトリを受信します。  
     - `UDP / Inbound / Port 14550 / Host <端末IP>` … アプリが送信するコマンドを PC が受け取ります。
  2. Windows ファイアウォールで UDP 14550 と 14551 の通信を許可します（初回はポップアップで許可）。
  3. **MAVLink Inspector** を開き、アプリ接続後に system ID 201 / component ID 191 のノードが現れることを確認します。

- **端末側の操作**
  - アプリの **Connect MAVLink** をタップすると、ログに `MAVLink GCS identity: systemId=201 componentId=191` と `Listening for MAVLink on 0.0.0.0:14551` が表示されます。
  - **Start Monitoring** でヒンジ連動制御を開始。AUTO/GUIDED/RTL ボタンなどでコマンド応答を確認できます。

## 使い方

### 基本フロー

1. **ドローン接続**  
   - `Connect MAVLink` ボタンでシミュレータ／実機に接続し、ステータスが Connected になるのを確認します。
2. **ヒンジ監視開始**  
   - `Start Monitoring` を押すとヒンジ角ストリームを購読し、角度に応じて自動制御します。
3. **テレメトリ確認**  
   - 地図にドローンマーカーと端末マーカー、軌跡が描画されます。下部カードで姿勢・位置を確認できます。
4. **手動操作**  
   - GUIDED / AUTO / RTL などのボタンでモード変更、Takeoff/Land で離着陸、`Send Heartbeat` で手動ハートビートを送信できます。

### ログと補助機能

- `Received MAVLink Messages` に直近 10 件の受信メッセージ種別を表示します。
- `Auto-pan to drone` のチェックを外すと、地図の中心を自由に移動してもパンが戻らなくなります。

## テスト

テストスイートには以下が含まれます。
- `HingeAngleService` のストリーム検証
- `MavlinkService` のモックソケットによる送受信テスト
- `DroneController` の 13 ケース（ヒンジ角判定、モード遷移、手動コマンドなど）

実行:

```bash
flutter test
```

## コード品質

```bash
# 自動修正
dart fix --apply

# 静的解析
flutter analyze

# フォーマット
dart format .
```

## 依存関係

### 本体
- `flutter`: クロスプラットフォーム開発用 SDK
- `dart_mavlink` (^0.1.0): MAVLink プロトコル実装
- `dual_screen` (^1.0.4): ヒンジ角取得
- `flutter_map` (^8.2.2): 地図コンポーネント
- `latlong2` (^0.9.1): 位置計算ユーティリティ
- `geolocator` (^13.0.2): 端末位置情報

### 開発向け
- `flutter_test`: テストフレームワーク
- `mocktail` (^1.0.4): モック生成
- `build_runner` (^2.9.0): コード生成
- `flutter_lints` (^5.0.0): Lint ルール

## ディレクトリ構成

```
drone_hinge_control/
├─ lib/
│  ├─ main.dart                       # エントリーポイント
│  ├─ data/services/                  # データ層サービス
│  │  ├─ mavlink_service.dart         # MAVLink 通信
│  │  ├─ hinge_angle_service.dart     # ヒンジ角取得
│  │  ├─ location_service.dart        # 位置情報取得
│  │  └─ raw_datagram_socket_service.dart # UDP 抽象化
│  ├─ domain/controllers/
│  │  └─ drone_controller.dart        # ビジネスロジック
│  └─ presentation/
│     ├─ screens/home_screen.dart     # メイン画面
│     └─ widgets/                     # UI コンポーネント
│        ├─ map_view.dart
│        └─ telemetry_view.dart
├─ test/                              # テストコード
├─ android/                           # Android 向け設定
├─ DESIGN.md                          # 設計ドキュメント（日本語）
├─ IMPLEMENTATION.md                  # 実装メモ（日本語）
└─ pubspec.yaml                       # 依存関係定義
```

## 技術メモ

- **MAVLink 通信**: UDP ソケット経由で ArduPilot 方言を使用し、Heartbeat / CommandLong / SetMode / RC Override などを送信。`GLOBAL_POSITION_INT` と `ATTITUDE` を解析して UI に配信します。
- **座標変換**: MAVLink では `度 × 10^7` の int32 を使用。表示時は小数度へ変換します。
- **状態管理**: 各サービスは broadcast `Stream` を公開し、`HomeScreen` が購読して UI を更新します。
- **パーミッション**: Android での位置情報権限を実行時に要求。インターネット権限は既定で有効です。

## 開発ノート

- **Mission Planner でのテスト**  
  1. Mission Planner を起動し Simulation タブから Multirotor を選択。  
  2. シミュレーション開始後、前述の UDP 設定を追加。  
  3. アプリで接続し、GUIDED/AUTO/RTL などのコマンドが反映されることを確認。

- **デバッグのヒント**  
  - `Received MAVLink Messages` のログで通信状況を確認。  
  - コンソールの `print` で接続イベントや送信コマンドを追跡。  
  - `flutter analyze` / `flutter test` で事前に静的解析とテストを実施。  
  - Mission Planner の MAVLink Inspector でメッセージ種別とレートを確認。

## 既知の制限

- ヒンジ角の取得は実機 Fold 端末に依存（エミュレータでは限定的）。
- GPS/ネットワーク状況により位置情報更新レートが変動。
- UAV 側の設定によっては追加の MAVLink 許可が必要。
- ログ出力に `print` を使用しているため、必要に応じてロガーへ移行する想定。

## 今後の拡張案

- Takeoff のチャンネル設定 UI
- ウェイポイントミッション作成と送信
- 飛行履歴の保存・リプレイ機能
- バッテリー残量やステータス警告の表示
- 複数機体の同時モニタリング
- カスタムタイルサーバーやオフラインマップ対応

## コントリビュート

学習用・実験用プロジェクトです。Issue、改善提案、プルリクエストを歓迎します。

## ライセンス

教育目的・実験目的で提供されるサンプルです。利用にあたっては自己責任でお願いします。

## 問い合わせ

- 設計詳細: `DESIGN.md`  
- 実装メモ: `IMPLEMENTATION.md`  
- 追加の質問や提案: リポジトリの Issue へ投稿してください。

---

**Target Device:** Samsung Galaxy Z Fold7  
**Development Date:** November 2025  
**Flutter Version:** 3.9.2+  
**Platform:** Android

（本ドキュメントは AI アシスタントの支援を受けて作成されました）
