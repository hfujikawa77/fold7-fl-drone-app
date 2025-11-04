# Implementation Plan: Drone Hinge Control

This document outlines the phased implementation plan for the Drone Hinge Control application.

## Journal

*This section will be updated after each phase to log actions, learnings, surprises, and deviations from the plan.*

### Phase 2: Hinge Angle Service Implementation (Completed)

**Date:** 2025-11-05

**Actions:**
- Implemented `HingeAngleService` using the `dual_screen` package to provide a stream of hinge angle data.
- Created a simple UI in `HomeScreen` to display the real-time hinge angle value.
- Created unit tests for `HingeAngleService` to verify the stream functionality.
- Ran code quality checks: `dart fix --apply`, `flutter analyze`, `dart format .`
- All tests passed successfully.

**Learnings:**
- The `dual_screen` package provides a straightforward API for accessing hinge angle data on foldable devices.
- Stream-based architecture works well for real-time sensor data.

**Deviations:**
- None. Implementation followed the design as planned.

### Phase 3: MAVLink Service and Basic Communication (Completed)

**Date:** 2025-11-05

**Actions:**
- Implemented `MavlinkService` to establish UDP connection with Mission Planner simulator.
- Created `RawDatagramSocketService` as an abstraction layer for UDP socket operations, making the code more testable.
- Implemented heartbeat message sending at regular intervals (1 Hz).
- Implemented message receiving and parsing using the `dart_mavlink` package.
- Created a UI to display connection status and received MAVLink messages.
- Created comprehensive unit tests for `MavlinkService`, including mocking of socket operations.
- Ran code quality checks and all tests passed.

**Learnings:**
- The `dart_mavlink` package provides good MAVLink protocol support, but requires careful buffer management.
- UDP socket operations need to be abstracted for testability, leading to the creation of `RawDatagramSocketService`.
- Connection state management is important for robust communication.

**Deviations:**
- Added `RawDatagramSocketService` as an additional abstraction layer not originally specified in the design. This improves testability and separation of concerns.

**Surprises:**
- The `dart_mavlink` package's API was straightforward to work with, making MAVLink integration easier than anticipated.

### Phase 4: Drone Control Logic (Completed)

**Date:** 2025-11-05

**Actions:**
- Implemented `DroneController` to connect `HingeAngleService` and `MavlinkService`.
- Implemented hinge angle monitoring with automatic arm/disarm based on angle thresholds:
  - 0-30 degrees: Disarm command
  - 60-120 degrees: Arm command
  - 150-180 degrees: RC override command
- Implemented manual control methods: `takeoff()`, `land()`, `setMode()`
- Added state tracking to prevent repeated commands for the same state
- Updated `HomeScreen` UI with:
  - Start/Stop monitoring buttons
  - Real-time hinge angle and drone state display
  - Manual control buttons (Takeoff, Land, Mode changes)
- Created comprehensive unit tests for `DroneController` with 13 test cases
- Ran code quality checks and all 18 tests passed successfully

**Learnings:**
- MAVLink command codes must be specified as numeric values rather than enum constants in dart_mavlink
- State tracking is essential to avoid sending redundant commands to the drone
- `RcChannelsOverride` message requires all 18 channels to be specified, even unused ones
- Mocktail requires fallback value registration for custom types like `MavlinkFrame`

**Deviations:**
- None. Implementation followed the design as specified

**Surprises:**
- The controller logic was straightforward to implement and test
- All unit tests passed on the first run after fixing the mocktail fallback registration

---

## Phase 1: Project Setup and Basic Structure

- [ ] Create a new Flutter project named `drone_hinge_control` in the current directory.
- [ ] Remove the default boilerplate code and tests (`lib/main.dart`, `test/widget_test.dart`).
- [ ] Update `pubspec.yaml` with the application description and set the version to `0.1.0`.
- [ ] Add necessary dependencies to `pubspec.yaml`:
    - `flutter_riverpod`
    - `riverpod_annotation` (for build_runner)
    - `dual_screen`
    - `dart_mavlink`
    - `flutter_map`
- [ ] Create a placeholder `README.md` file.
- [ ] Create a `CHANGELOG.md` file with the initial version `0.1.0`.
- [ ] Create the directory structure as defined in `DESIGN.md`.
- [ ] Create empty files for the services, controllers, and UI components defined in the design.
- [ ] Commit the initial project structure to the `feature/drone-hinge-control-app` branch.
- [ ] After completing a task, if you added any TODOs to the code or didn't fully implement anything, make sure to add new tasks so that you can come back and complete them later.

---

## Phase 2: Hinge Angle Service Implementation

- [x] Implement the `HingeAngleService` to provide a stream of hinge angle data using the `dual_screen` package.
- [x] Create a simple UI to display the hinge angle value to verify the service is working.
- [x] Create unit tests for the `HingeAngleService`.
- [x] Run `dart fix --apply` to clean up the code.
- [x] Run `flutter analyze` and fix any issues.
- [x] Run tests to ensure they all pass.
- [x] Run `dart format .` to format the code.
- [x] Re-read `IMPLEMENTATION.md` to see what, if anything, has changed.
- [x] Update the `IMPLEMENTATION.md` file with the current state.
- [ ] Use `git diff` to verify the changes and create a commit message.
- [ ] Wait for user approval before committing.

---

## Phase 3: MAVLink Service and Basic Communication

- [x] Implement the basic `MavlinkService` to connect to the Mission Planner simulator via UDP.
- [x] Implement methods for sending heartbeat messages.
- [x] Implement methods for receiving messages and parsing them.
- [x] Create a simple UI to display connection status and received messages to verify the service.
- [x] Create unit tests for the `MavlinkService`.
- [x] Run `dart fix --apply` to clean up the code.
- [x] Run `flutter analyze` and fix any issues.
- [x] Run tests to ensure they all pass.
- [x] Run `dart format .` to format the code.
- [x] Re-read `IMPLEMENTATION.md` to see what, if anything, has changed.
- [x] Update the `IMPLEMENTATION.md` file with the current state.
- [ ] Use `git diff` to verify the changes and create a commit message.
- [ ] Wait for user approval before committing.

---

## Phase 4: Drone Control Logic

- [x] Implement the `DroneController` to connect the `HingeAngleService` and `MavlinkService`.
- [x] Implement the logic to arm/disarm the drone based on the hinge angle.
- [x] Implement the logic to send RC override commands at 180 degrees.
- [x] Implement the takeoff and land commands.
- [x] Implement the mode change commands.
- [x] Create a UI with buttons to test the takeoff, land, and mode change functionalities.
- [x] Create unit tests for the `DroneController`.
- [x] Run `dart fix --apply` to clean up the code.
- [x] Run `flutter analyze` and fix any issues.
- [x] Run tests to ensure they all pass.
- [x] Run `dart format .` to format the code.
- [x] Re-read `IMPLEMENTATION.md` to see what, if anything, has changed.
- [x] Update the `IMPLEMENTATION.md` file with the current state.
- [ ] Use `git diff` to verify the changes and create a commit message.
- [ ] Wait for user approval before committing.

---

## Phase 5: Map and Telemetry UI (In Progress)

- [ ] Implement the `MapView` using `flutter_map`.
- [ ] Display the drone's position on the map based on the data from `MavlinkService`.
- [ ] Display the device's current location on the map.
- [ ] Implement the `TelemetryView` to display attitude, altitude, and other data from `MavlinkService`.
- [ ] Integrate the `MapView` and `TelemetryView` into the main screen.
- [x] Add required dependencies (`flutter_map`, `latlong2`, `geolocator`) to `pubspec.yaml`.
- [ ] Run `dart fix --apply` to clean up the code.
- [ ] Run `flutter analyze` and fix any issues.
- [ ] Run tests to ensure they all pass.
- [ ] Run `dart format .` to format the code.
- [ ] Re-read `IMPLEMENTATION.md` to see what, if anything, has changed.
- [ ] Update the `IMPLEMENTATION.md` file with the current state.
- [ ] Use `git diff` to verify the changes and create a commit message.
- [ ] Wait for user approval before committing.

**Note:** Phase 5 implementation has been started with dependency setup but will be completed in the next session.

---

## Phase 6: Finalization

- [ ] Create a comprehensive `README.md` file for the package.
- [ ] Create a `GEMINI.md` file in the project directory that describes the app, its purpose, and implementation details of the application and the layout of the files.
- [ ] Ask the user to inspect the app and the code and say if they are satisfied with it, or if any modifications are needed.