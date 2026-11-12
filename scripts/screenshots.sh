#!/bin/bash
# Runs the built app in an iPhone simulator and photographs the sea at several
# times of day and in several kinds of weather. Pictures go to out/screenshots.
set -euo pipefail

APP="build/Build/Products/Debug-iphonesimulator/Marin.app"
BUNDLE="com.krowsingre.marin"
OUT="out/screenshots"
mkdir -p "$OUT"

# Pick an iPhone from the newest installed iOS simulator runtime.
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys, re
devices = json.load(sys.stdin)["devices"]
def version(runtime):
    return [int(n) for n in re.findall(r"\d+", runtime.split("iOS")[-1])]
runtimes = sorted((r for r in devices if "iOS" in r), key=version, reverse=True)
for runtime in runtimes:
    phones = [d for d in devices[runtime] if d["name"].startswith("iPhone")]
    plain = [d for d in phones if not any(w in d["name"] for w in ("Pro", "Plus", "SE", "mini", "Air"))]
    chosen = (plain or phones)
    if chosen:
        print(chosen[0]["udid"])
        break
')

if [ -z "$UDID" ]; then
  echo "No iPhone simulator found" >&2
  exit 1
fi
echo "Using simulator $UDID"
xcrun simctl list devices | grep "$UDID" || true

xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" "$APP"

shoot() {
  local name="$1"
  shift
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE" "$@"
  sleep 9
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png"
}

# The first launch is slow, so warm the app up once before taking pictures.
xcrun simctl launch "$UDID" "$BUNDLE" -seaHour 12 -seaWeather clear
sleep 15

shoot 1-dawn  -seaHour 6    -seaWeather clear
shoot 2-noon  -seaHour 12   -seaWeather clear
shoot 3-dusk  -seaHour 18.8 -seaWeather cloudy
shoot 4-night -seaHour 23   -seaWeather clear
shoot 5-storm -seaHour 15   -seaWeather storm

xcrun simctl shutdown "$UDID" || true
ls -la "$OUT"
