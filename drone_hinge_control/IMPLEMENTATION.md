# Implementation Plan: Drone Hinge Control

This document outlines the phased implementation plan for the Drone Hinge Control application.

## Journal

*This section will be updated after each phase to log actions, learnings, surprises, and deviations from the plan.*

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
- [ ] Re-read `IMPLEMENTATION.md` to see what, if anything, has changed.
- [ ] Update the `IMPLEMENTATION.md` file with the current state.
- [ ] Use `git diff` to verify the changes and create a commit message.
- [ ] Wait for user approval before committing.

---

## Phase 3: MAVLink Service and Basic Communication

- [ ] Implement the basic `MavlinkService` to connect to the Mission Planner simulator via UDP.
- [ ] Implement methods for sending heartbeat messages.
- [ ] Implement methods for receiving messages and parsing them.
- [ ] Create a simple UI to display connection status and received messages to verify the service.
- [ ] Create unit tests for the `MavlinkService`.
- [ ] Run `dart fix --apply` to clean up the code.
- [ ] Run `flutter analyze` and fix any issues.
- [ ] Run tests to ensure they all pass.
- [ ] Run `dart format .` to format the code.
- [ ] Re-read `IMPLEMENTATION.md` to see what, if anything, has changed.
- [ ] Update the `IMPLEMENTATION.md` file with the current state.
- [ ] Use `git diff` to verify the changes and create a commit message.
- [ ] Wait for user approval before committing.

---

## Phase 4: Drone Control Logic

- [ ] Implement the `DroneController` to connect the `HingeAngleService` and `MavlinkService`.
- [ ] Implement the logic to arm/disarm the drone based on the hinge angle.
- [ ] Implement the logic to send RC override commands at 180 degrees.
- [ ] Implement the takeoff and land commands.
- [ ] Implement the mode change commands.
- [ ] Create a UI with buttons to test the takeoff, land, and mode change functionalities.
- [ ] Create unit tests for the `DroneController`.
- [ ] Run `dart fix --apply` to clean up the code.
- [ ] Run `flutter analyze` and fix any issues.
- [ ] Run tests to ensure they all pass.
- [ ] Run `dart format .` to format the code.
- [ ] Re-read `IMPLEMENTATION.md` to see what, if anything, has changed.
- [ ] Update the `IMPLEMENTATION.md` file with the current state.
- [ ] Use `git diff` to verify the changes and create a commit message.
- [ ] Wait for user approval before committing.

---

## Phase 5: Map and Telemetry UI

- [ ] Implement the `MapView` using `flutter_map`.
- [ ] Display the drone's position on the map based on the data from `MavlinkService`.
- [ ] Display the device's current location on the map.
- [ ] Implement the `TelemetryView` to display attitude, altitude, and other data from `MavlinkService`.
- [ ] Integrate the `MapView` and `TelemetryView` into the main screen.
- [ ] Run `dart fix --apply` to clean up the code.
- [ ] Run `flutter analyze` and fix any issues.
- [ ] Run tests to ensure they all pass.
- [ ] Run `dart format .` to format the code.
- [ ] Re-read `IMPLEMENTATION.md` to see what, if anything, has changed.
- [ ] Update the `IMPLEMENTATION.md` file with the current state.
- [ ] Use `git diff` to verify the changes and create a commit message.
- [ ] Wait for user approval before committing.

---

## Phase 6: Finalization

- [ ] Create a comprehensive `README.md` file for the package.
- [ ] Create a `GEMINI.md` file in the project directory that describes the app, its purpose, and implementation details of the application and the layout of the files.
- [ ] Ask the user to inspect the app and the code and say if they are satisfied with it, or if any modifications are needed.