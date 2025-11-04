
# 設計ドキュメント: Drone Hinge Control

## 1. 概要

このドキュメントは、MAVLink対応ドローンを折りたたみデバイスのヒンジ角度で操作するFlutterアプリケーション「Drone Hinge Control」の設計について記述します。

このアプリケーションは、Galaxy Z Fold7をターゲットデバイスとし、ヒンジの角度に応じてドローンのアーム、ディスアーム、およびRC制御を行います。さらに、地図上でのドローンの位置表示、離着陸、飛行モードの変更、各種テレメトリ情報（位置、姿勢）の表示機能も提供します。

## 2. 目標と課題分析

### 2.1. 目標

*   折りたたみデバイスのヒンジ角度を利用した、直感的で新しいドローン操縦体験の実現。
*   MAVLinkプロトコルによるドローンとの安定した通信。
*   地図、テレメトリ表示など、ドローン操縦に必要な基本機能を備えたUIの提供。
*   Mission Plannerのシミュレータ環境での検証を可能にすること。

### 2.2. 課題

*   **ヒンジ角度の取得:** FlutterでGalaxy Z Fold7のヒンジ角度をリアルタイムかつ正確に取得する方法の確立。
*   **MAVLink通信:** Dart/Flutter環境でMAVLinkメッセージの送受信を安定して行うためのライブラリ選定または実装。
*   **UI/UX設計:** 折りたたみデバイスの特性（画面サイズの変化、ヒンジの存在）を考慮した、使いやすいUI/UXの設計。
*   **ドローン制御ロジック:** ヒンジ角度とドローンの各アクション（アーム/ディスアーム、RC入力）を安全に結びつける制御ロジックの構築。

## 3. 検討した代替案

### 3.1. ヒンジ角度取得

*   **案1: `dual_screen` パッケージの利用 (採用)**
    *   **利点:** Microsoftが開発しており、デュアルスクリーンや折りたたみデバイスの情報を取得するために設計されている。ヒンジ角度のストリームを提供しており、今回の要件に最適。
    *   **欠点:** 外部パッケージへの依存。
*   **案2: Platform Channelによるネイティブ実装**
    *   **利点:** デバイス固有のAPIを直接利用できるため、最も確実性が高い。
    *   **欠点:** 実装コストが高い。Android (Kotlin/Java) の知識が別途必要になる。

### 3.2. MAVLink通信

*   **案1: `dart_mavlink` パッケージの利用 (採用)**
    *   **利点:** 既存のDart製MAVLinkライブラリであり、基本的なメッセージの送受信機能が期待できる。開発コストを削減できる。
    *   **欠点:** 更新頻度が低く、コミュニティが活発でない可能性がある。問題発生時に自力での解決が必要になる場合がある。
*   **案2: MAVLinkプロトコルの独自実装**
    *   **利点:** プロトコルの全てを把握でき、アプリケーションに最適化された実装が可能。
    *   **欠点:** 実装に膨大な時間と労力がかかる。プロトコル仕様の深い理解が必要。

### 3.3. 地図表示

*   **案1: `flutter_map` パッケージの利用 (採用)**
    *   **利点:** オープンソースでカスタマイズ性が高い。タイルサーバーを自由に選択でき、オフライン対応も可能。商用利用の制約が少ない。
    *   **欠点:** Google Maps Platformほどの多機能性はない場合がある。
*   **案2: `google_maps_flutter` パッケージの利用**
    *   **利点:** Googleによる公式パッケージで、信頼性が高い。Google Mapsの豊富な機能（ストリートビューなど）を利用できる。
    *   **欠点:** APIキーの取得が必要。商用利用時にコストが発生する可能性がある。

## 4. 詳細設計

### 4.1. アーキテクチャ

アプリケーションは、関心の分離を徹底するため、以下の3層からなるレイヤードアーキテクチャを採用します。

```mermaid
graph TD
    A[UI Layer (Presentation)] --> B[Business Logic Layer (Domain)]
    B --> C[Data/Service Layer]

    subgraph C[Data/Service Layer]
        C1[MavlinkService]
        C2[HingeAngleService]
        C3[LocationService]
    end

    subgraph B[Business Logic Layer (Domain)]
        B1[DroneController]
        B2[MapController]
        B3[UIStateNotifier]
    end

    subgraph A[UI Layer (Presentation)]
        A1[MapView]
        A2[TelemetryView]
        A3[ControlPanel]
    end
```

*   **UI Layer:** 画面描画に責任を持つ。`flutter_map`を使った地図表示、ドローンの状態表示など。ユーザーからの入力を受け付け、Business Logic Layerに伝達する。
*   **Business Logic Layer:** アプリケーションのビジネスロジックを担当する。`DroneController`がヒンジ角度やユーザーの操作に応じて、`MavlinkService`を通じてドローンにコマンドを送信する。`UIStateNotifier`がUIの状態を管理する。
*   **Data/Service Layer:** 外部とのやり取りを担当するサービス群。
    *   `MavlinkService`: MAVLink通信を行い、ドローンとのメッセージを送受信する。
    *   `HingeAngleService`: デバイスのヒンジ角度をストリームとして提供する。
    *   `LocationService`: デバイスのGPS位置情報を取得する。

### 4.2. 状態管理

`Riverpod` を採用し、各レイヤー間の依存関係を管理し、状態の変更を効率的にUIに伝播させます。`Provider` や `StateNotifierProvider` を用いて、各ServiceやControllerをUI Layerに提供します。

### 4.3. 主要コンポーネント

#### 4.3.1. HingeAngleService

*   `dual_screen` パッケージを利用し、ヒンジ角度の変更を `Stream<double>` として提供する。
*   エラーハンドリング（センサーが利用できない場合など）を実装する。

#### 4.3.2. MavlinkService

*   `dart_mavlink` パッケージを利用し、UDP経由でMission Plannerシミュレータまたは実機と通信する。
*   ドローンへのコマンド送信（アーム、ディスアーム、モード変更、RC入力など）メソッドを提供する。
*   ドローンからのテレメトリ受信（位置情報、姿勢情報など）を行い、`Stream` として外部に公開する。

#### 4.3.3. DroneController

*   `HingeAngleService` からのヒンジ角度ストリームを監視する。
*   ヒンジ角度に応じて、`MavlinkService` を通じて以下のコマンドを送信する。
    *   **0度付近:** `COMMAND_LONG(MAV_CMD_COMPONENT_ARM_DISARM, 0)` (Disarm)
    *   **90度付近:** `COMMAND_LONG(MAV_CMD_COMPONENT_ARM_DISARM, 1)` (Arm)
    *   **180度付近:** `MANUAL_CONTROL` または `RC_CHANNELS_OVERRIDE` メッセージを送信し、特定のRC入力をエミュレートする。
*   UIからの離着陸、モード変更要求を受け付け、対応するMAVLinkコマンドを送信する。

#### 4.3.4. UI

*   **MapView (`flutter_map`):**
    *   `MavlinkService` から受信したドローンの位置情報を地図上にマーカーとして表示する。
    *   デバイスの現在位置も表示する。
*   **TelemetryView:**
    *   `MavlinkService` から受信した姿勢情報（Roll, Pitch, Yaw）、バッテリー残量などを表示する。
*   **ControlPanel:**
    *   離着陸ボタン、モード変更用ドロップダウンなどを配置する。
    *   現在のヒンジ角度と、それに対応するドローンの状態を表示する。

### 4.4. ディレクトリ構成

```
drone_hinge_control/
├── lib/
│   ├── main.dart
│   ├── presentation/  (UI Layer)
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   ├── widgets/
│   │   │   ├── map_view.dart
│   │   │   └── telemetry_view.dart
│   ├── domain/          (Business Logic Layer)
│   │   ├── controllers/
│   │   │   └── drone_controller.dart
│   │   └── notifiers/
│   │       └── ui_state_notifier.dart
│   └── data/            (Data/Service Layer)
│       ├── services/
│       │   ├── mavlink_service.dart
│       │   └── hinge_angle_service.dart
│       └── models/
│           └── drone_state.dart
├── test/
└── pubspec.yaml
```

## 5. 設計の概要

本設計では、Flutterのモダンな開発手法（レイヤードアーキテクチャ、Riverpodによる状態管理）を採用し、保守性と拡張性の高いアプリケーションを目指します。外部パッケージを効果的に利用することで、開発効率を高めます。特に、`dual_screen`によるヒンジ角度取得、`dart_mavlink`による通信、`flutter_map`による地図表示を設計の中核に据えています。

## 6. 参考URL

*   **Hinge Angle / Foldable Devices:**
    *   [Microsoft - Developing for dual-screen and foldable devices with Flutter](https://docs.microsoft.com/en-us/dual-screen/flutter/)
    *   [pub.dev - dual_screen package](https://pub.dev/packages/dual_screen)
*   **MAVLink:**
    *   [pub.dev - dart_mavlink package](https://pub.dev/packages/dart_mavlink)
    *   [MAVLink Protocol Official Website](https://mavlink.io/en/)
*   **Map Display:**
    *   [pub.dev - flutter_map package](https://pub.dev/packages/flutter_map)
