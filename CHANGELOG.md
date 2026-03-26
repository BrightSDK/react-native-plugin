# Changelog

## 2.0.4

### Added
- Example app with scaffold script and React Native demo
  (init, consent, enable/disable flow).

## 2.0.3

### Added
- File logger on Windows: SDK diagnostic messages are now written to
  `%TEMP%\brightsdk.log` in addition to `OutputDebugStringW`, making it easier
  to troubleshoot MSIX-packaged deployments.

### Fixed
- Add `BrightSdkModule.def` to export `DllGetActivationFactory`, fixing WinRT
  activation failures when the module is loaded by the React Native Windows host.
- Add `ReactPackageProvider.idl` and `BrightSdkModule.def` to the published
  `files` whitelist and test expectations.

### Changed
- Removed stale `.tgz` files from the repository; added `*.tgz` to `.gitignore`.

## 2.0.2

### Fixed
- Add `ReactPackageProvider.idl` so the plugin produces a proper WinMD, fixing
  `cppwinrt_ref.rsp` failures during the MSIX packaging build pass.
- Add `factory_implementation` namespace to `ReactPackageProvider.h`, required
  by the generated `.g.cpp` from the IDL.
- Move `ConfigurationType` into `PropertyGroup Label="Globals"` so MSBuild
  evaluates it before `Microsoft.Cpp.Default.props` (fixes LNK2019 WinMain).

### Changed
- Updated docs and README for the 2.0.1 wrapper API surface.

## 2.0.1

### Added
- `getConsentChoice()`, `getUuid()`, `closeSdk()` methods to the Android
  native bridge (`BrightSdkNativeModule.java`).
- Null-safe wrapper in `index.js` � all methods use optional chaining and
  return safe defaults (`Promise.resolve(null)`) when the native module is
  unavailable.

### Changed
- `index.js` now exports a high-level API object instead of the raw
  `NativeModules.BrightSdkNativeModule` reference.

## 2.0.0

### Added
- **Windows support** via `react-native-windows` autolinking.
- `windows/BrightSdkModule/` � C++/WinRT native module that dynamically loads
  `lum_sdk.dll` via `LoadLibraryW` with graceful fallback.
- `react-native.config.js` for Windows autolinking.
- `react-native-windows` key in `package.json` with project reference.
- Windows-specific tests in `tests/package.test.mjs`.
- Updated `README.md` and `docs/react-native-plugin.md` with Windows
  integration instructions.

## 1.0.6

### Added
- Unit tests (`tests/package.test.mjs`).
- GitHub Actions release workflow.
- README workflow badges.

## 1.0.5

### Fixed
- Pass activity context to `init()` on Android.

## 1.0.4

### Fixed
- Add missing `init` call in Android bridge.

## 1.0.3

### Changed
- Version bump.

## 1.0.2

### Changed
- Use project properties to configure BrightSDK on Android.

## 1.0.1

### Fixed
- Set `useMavenLocal=true` for Android builds.

## 1.0.0

### Added
- Initial release with Android support.
- `BrightSdkNativeModule` with `initBrightSdk`, `reportConsentShown`,
  `handleConsentChange` methods.
- Auto-linking via `react-native` config in `package.json`.
