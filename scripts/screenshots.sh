#!/bin/bash
# Runs the built app in an iPhone simulator and photographs the sea at several
# times of day and in several kinds of weather. Pictures go to out/screenshots.
set -euo pipefail

APP="build/Build/Products/Debug-iphonesimulator/Marin.app"
BUNDLE="com.krowsingre.MarinatSoT"
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
  xcrun simctl launch "$UDID" "$BUNDLE" -seaHome "${HOME_SCREEN:-0}" "$@"
  sleep 9
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png"
  # The game is played in landscape. If the picture comes out upright, turn it on its side.
  local w h
  w=$(sips -g pixelWidth "$OUT/$name.png" | awk '/pixelWidth/ {print $2}')
  h=$(sips -g pixelHeight "$OUT/$name.png" | awk '/pixelHeight/ {print $2}')
  if [ "$h" -gt "$w" ]; then
    sips -r "${ROTATE:-270}" "$OUT/$name.png" >/dev/null
  fi
}

# The first launch is slow, so warm the app up once before taking pictures.
xcrun simctl launch "$UDID" "$BUNDLE" -seaHour 12 -seaWeather clear
sleep 15

HOME_SCREEN=1 shoot 0-home-first-time -seaHour 18.4 -seaWeather clear
HOME_SCREEN=1 shoot 0-home-returning -seaHour 18.4 -seaWeather clear -seaCompose 1
shoot 1-sailing-day    -seaHour 10   -seaWeather clear
shoot 2-under-way-dusk -seaHour 18.6 -seaWeather clear -seaSailing 1
shoot 3-farther-on     -seaHour 13   -seaWeather cloudy -seaWorldX 5200
shoot 4-fishing-day    -seaHour 11   -seaWeather clear -seaFishing 1
shoot 5-fishing-night  -seaHour 22   -seaWeather clear -seaFishing 1 -seaWorldX 2400
shoot 6-storm          -seaHour 15   -seaWeather storm
shoot 7-bottle-on-line -seaHour 11   -seaWeather clear -seaFishing 1 -seaBite 1
shoot 8-bottle-opened  -seaHour 11   -seaWeather clear -seaCatch 1
shoot 9-composing      -seaHour 11   -seaWeather clear -seaCompose 1
shoot 10-magic-half    -seaHour 11   -seaWeather clear -seaFishing 1 -seaMagic 0.5
shoot 11-magic-full    -seaHour 11   -seaWeather clear -seaFishing 1 -seaMagic 1
shoot 12-magic-night   -seaHour 22   -seaWeather clear -seaMagic 1

xcrun simctl shutdown "$UDID" || true
ls -la "$OUT"
