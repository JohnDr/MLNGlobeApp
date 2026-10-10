# MapLibreEarth

A Qt Quick / QML map application built on [MapLibre Native Qt](https://github.com/maplibre/maplibre-native-qt).

This project started as the upstream `examples/quick-standalone` example and is
now developed independently. It uses the installed `QMapLibre` CMake package
(`find_package(QMapLibre COMPONENTS Core Quick)`), so it is built as its own
CMake project rather than from inside the `maplibre-native-qt` tree.

## Features

- Style picker ("Maps" dialog): Liberty / Bright / Positron (OpenFreeMap) and
  Open Waters, plus user-added style URLs; runtime style switching.
- Camera presets ("Presets" dialog): named, persisted, click to fly to.
- Settings dialog: application scale (`QT_SCALE_FACTOR`) with restart.
- Dark / light Material theme switch.
- 2D / 3D tilted toggle, 3D-buildings toggle.
- Zoom buttons; wheel = stepped zoom; left-drag = pan; right-drag = smooth
  zoom (desktop); two-finger pinch = zoom.

## Requirements

- Qt 6 (Quick, QuickControls2), e.g. `C:\Qt\6.12.0\msvc2022_64`
- A `QMapLibre` install (from a `maplibre-native-qt` build). See "Dependency"
  below.

## Build (Windows)

```powershell
$env:QT_ROOT_DIR = "C:\Qt\6.12.0\msvc2022_64"
$env:QMapLibre_DIR = "C:\path\to\install\maplibre-native-qt\lib\cmake\QMapLibre"

cmake -S . -B build -G Ninja `
      -DCMAKE_PREFIX_PATH=$env:QT_ROOT_DIR `
      -DQMapLibre_DIR=$env:QMapLibre_DIR `
      -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

Or open `CMakeLists.txt` in Qt Creator (the bundled `CMakePresets.json`
provides a `default` preset that reads `QT_ROOT_DIR` and `QMapLibre_DIR`).

Run: `build\MapLibreEarth.exe`. If the DLLs are not found, put the
`QMapLibre` `bin` directory (and Qt's `bin`) on `PATH`.

## Dependency

MapLibreEarth relies on two `QMapLibre` library behaviours that live in
`maplibre-native-qt`:

- runtime `setStyle` reload (so the Maps dialog switches styles immediately), and
- right-button event delivery on the map item (so right-drag zoom works).

Until those are available in an upstream release, build the `QMapLibre`
install from the fork/branch that contains them. The Open Waters style also
uses newer MapLibre style-spec properties (`icon-overlap`, `text-overlap`,
data-driven `line-dasharray`, `resampling`); rendering those (e.g. buoys)
requires a MapLibre Native build that supports them.

## License

MIT. See [LICENSE](LICENSE).
