# Drone Hinge Control

A Flutter application that enables intuitive drone control using the hinge angle of foldable devices like the Samsung Galaxy Z Fold7. This app communicates with MAVLink-compatible drones and provides real-time telemetry, map visualization, and innovative hinge-based control.

## Features

### Core Functionality

- **Hinge Angle-Based Control**: Control drone states using your foldable device's hinge angle
  - 0-30°: Disarm
  - 60-120°: Arm
  - 150-180°: RC Override
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
- State management for arm/disarm/RC override based on hinge angle thresholds

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
| 150-180° | RC Override | Send RC channel override commands |

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
