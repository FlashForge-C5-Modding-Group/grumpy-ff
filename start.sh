#!/bin/sh
# Start GrumpyScreen on a FlashForge printer. The touchscreen's event number
# depends on driver load order, so find it by name instead of assuming one -
# any input device with "Touchscreen" in its name, same rule as FlashForge's
# app_startup.sh.
DIR=$(dirname "$(readlink -f "$0")")

for d in /sys/class/input/event*; do
	case "$(cat "$d/device/name" 2>/dev/null)" in
	*Touchscreen*)
		LVGL_EVDEV_DEV=/dev/input/${d##*/}
		break
		;;
	esac
done
if [ -z "$LVGL_EVDEV_DEV" ]; then
	echo "grumpyscreen: no Touchscreen input device"
	exit 1
fi
echo "grumpyscreen: touch $LVGL_EVDEV_DEV"

export LVGL_EVDEV_DEV
# grumpyscreen needs a valid working directory (it reads the current path)
cd "$DIR" || exit 1
exec ./grumpyscreen
