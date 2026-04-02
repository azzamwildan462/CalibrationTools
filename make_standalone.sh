#!/bin/bash
# =============================================================
#  Sensor Calibration Workspace - Build Script
#  Usage:
#    ./make.sh                    # build all
#    ./make.sh --packages-select lidar_imu_calibrator
# =============================================================

set -e
cd "$(dirname "$0")"

source /opt/ros/humble/setup.bash

TARGETS="sensor_calibration_tools lidar_imu_calibrator"

# ---- Step 1: Auto-ignore unneeded autoware packages ----
echo "[1/3] Resolving dependencies..."
NEEDED=$(colcon list --packages-up-to $TARGETS -n 2>/dev/null | sort)

for BASE in src/autoware/universe src/autoware/autoware_core; do
    [ ! -d "$BASE" ] && continue
    for pkg_path in $(colcon list --base-paths "$BASE" -p 2>/dev/null); do
        pkg_name=$(colcon list --base-paths "$pkg_path" -n 2>/dev/null)
        if ! echo "$NEEDED" | grep -qx "$pkg_name"; then
            touch "$pkg_path/COLCON_IGNORE" 2>/dev/null
        else
            rm -f "$pkg_path/COLCON_IGNORE" 2>/dev/null
        fi
    done
done

# ---- Step 2: Install rosdep dependencies ----
if [ "$1" = "--with-deps" ]; then
    shift
    echo "[*] Installing rosdep dependencies..."
    rosdep install -y --from-paths src --ignore-src --rosdistro humble 2>/dev/null || true
fi

# ---- Step 3: Build ----
PKG_COUNT=$(echo "$NEEDED" | wc -l)
echo "[2/3] Building $PKG_COUNT packages..."
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release "$@"

echo "[3/3] Done."
echo "  source install/setup.bash"
