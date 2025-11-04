# Drone Hinge Control App Requirements

## App Purpose

An application to communicate with a drone using MAVLink and control the drone using the hinge angle of a foldable device.

## Collected Information

-   **App Name:** `drone_hinge_control`
-   **Target Device:** Galaxy Z Fold7
-   **Drone Details:** A custom-built drone capable of MAVLink communication. Initial testing will be done with the Mission Planner simulator.
-   **Control Scheme:**
    -   Closed state (0 degrees): Disarm
    -   90 degrees: Arm
    -   180 degrees: Specific RC input
-   **Other Features:**
    -   Map display
    -   Takeoff and landing functionality
    -   Mode change functionality
    -   Display of position and attitude information
-   **Development Branch:** `feature/drone-hinge-control-app`