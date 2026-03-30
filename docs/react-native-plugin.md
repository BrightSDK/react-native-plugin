<p align="center">
  <a href="https://bright-sdk.com/"><img src="assets/brightsdk-logo.svg" alt="BrightSDK" height="50"></a>
  &nbsp;&nbsp;&nbsp;✕&nbsp;&nbsp;&nbsp;
  <a href="https://reactnative.dev/"><img src="assets/react-native-logo.svg" alt="React Native" height="50"></a>
</p>

# react-native-bright-sdk

GitHub: https://github.com/BrightSDK/react-native-plugin  
Package: `react-native-bright-sdk`  
Current version: `2.0.3`  
License: MIT

## Overview

`react-native-bright-sdk` is a React Native bridge for BrightSDK supporting Android and Windows. It exposes a small JavaScript API backed by native platform modules so app code can:

- initialize BrightSDK,
- apply user consent decisions (opt-in / opt-out),
- report that consent UI was shown.

Current platform support from source:
- Android: supported
- Windows: supported (C++/WinRT via `react-native-windows`)
- iOS/macOS: planned (not implemented in this repository yet)

## Public JavaScript API

The package exports a wrapper API from React Native `NativeModules`:

```js
import { NativeModules } from 'react-native';

const sdk = NativeModules.BrightSdkNativeModule || {};

export default {
  init: () => sdk.initBrightSdk?.(),
  setAppId: (appId) => sdk.setAppId?.(appId),
  reportConsentShown: () => sdk.reportConsentShown?.(),
  enable: () => sdk.handleConsentChange?.(true),
  disable: () => sdk.handleConsentChange?.(false),
  getConsentChoice: () => sdk.getConsentChoice?.() ?? Promise.resolve(null),
  getUuid: () => sdk.getUuid?.() ?? Promise.resolve(null),
  close: () => sdk.closeSdk?.(),
};
```

### Methods exposed to JS (all platforms)

1. `initBrightSdk(): void`
- Initializes BrightSDK using the current platform context.

2. `handleConsentChange(value: boolean): Promise<boolean>`
- `true` -> calls native enable (Android: `BrightApi.externalOptIn`, Windows: `brd_sdk_opt_in_c`)  
- `false` -> calls native disable (Android: `BrightApi.optOut`, Windows: `brd_sdk_opt_out_c`)  
- Resolves `true` on completion.

3. `reportConsentShown(): Promise<boolean>`
- Calls `BrightApi.reportConsentShown(context)` on Android.
- No-op on Windows (logged via `OutputDebugString`).
- Resolves `true` on completion.

### Additional methods (Windows only)

4. `setAppId(appId: string): void`
- Sets the application ID. Should be called before `initBrightSdk()`.

5. `fixServiceStatus(): void`
- Attempts to repair the SDK service status.

### Cross-platform methods (Android + Windows)

6. `getConsentChoice(): Promise<boolean | null>`
- Returns `true` (peer), `false` (not peer), or `null` (unknown).
- Android: delegates to `BrightApi.getConsentChoice(context)`.
- Windows: delegates to `brd_sdk_get_consent_choice_c`.

7. `getUuid(): Promise<string | null>`
- Returns the SDK-assigned UUID, or `null` if unavailable.
- Android: delegates to `BrightApi.getSdkUuid(context)`.
- Windows: delegates to `brd_sdk_get_uuid_c`.

8. `closeSdk(): void`
- Shuts down the SDK and releases resources.
- Android: no-op (SDK lifecycle is tied to the app process).
- Windows: calls `brd_sdk_close_c` and unloads the DLL.

## Android Native Architecture

### Bridge module

`android/src/main/java/com/brightsdk/react/BrightSdkNativeModule.java`

- Extends `ReactContextBaseJavaModule`
- Exposed module name: `BrightSdkNativeModule`
- JS-callable methods are annotated with `@ReactMethod`
- Delegates all BrightSDK operations to a singleton helper (`BrightSdkHelper`)

### Package registration

`android/src/main/java/com/brightsdk/react/BrightSdkNativeModulePackage.java`

- Implements `ReactPackage`
- Registers one native module: `BrightSdkNativeModule`
- No custom view managers (`Collections.emptyList()`)

### BrightSDK helper wrapper

`android/src/main/java/com/brightsdk/react/BrightSdkHelper.java`

- Singleton accessor: `getInstance()`
- Thin wrapper over `com.android.eapx.BrightApi`
- Methods:
  - `init(Activity)`
  - `start(Context, Settings)`
  - `enable(Context)`
  - `disable(Context)`
  - `reportConsentShown(Context)`
  - `getConsentChoice(Context)` — returns `int` from `BrightApi.getConsentChoice`
  - `getSdkUuid(Context)` — returns `String` from `BrightApi.getSdkUuid`

#### Initialization defaults in source

On `init(Activity)` the helper creates `Settings` and sets:

- `setSkipConsent(true)`
- `setMinJobId(1)`
- `setMaxJobId(1000)`

Then runs `BrightApi.init(context, settings)`.

That means consent UI is expected to be app-controlled from JS; the native SDK built-in consent screen is skipped.

## Build and SDK Wiring (Android)

`android/build.gradle` configures this package as an Android library and applies BrightSDK Gradle integration:

- `com.android.tools.build:gradle:8.1.0`
- `com.brightdata:bright-sdk-gradle:1.+`
- `compileSdkVersion 35`
- `targetSdkVersion 35`
- `minSdkVersion 21`

BrightSDK extension values used in source:

```groovy
ext.brightsdk = [
    useMavenLocal: true,
    version: "latest",
    ext: "brightsdk",
    consumerProjects: "react-native-bright-sdk,app",
]
```

The build enforces SDK installation before compilation:

- `preBuild` depends on `installBrightSdk`

This is wired in `afterEvaluate` so BrightSDK artifacts are prepared before Android build tasks execute.

## Package Metadata and Auto-Linking

`package.json` defines:

- name: `react-native-bright-sdk`
- main entry: `index.js`
- peer dependencies:
  - `react >= 17.0.0`
  - `react-native >= 0.68.0`

Android autolinking metadata:

```json
"react-native": {
  "android": {
    "packageImportPath": "import com.brightsdk.react.BrightSdkNativeModulePackage;",
    "packageInstance": "new BrightSdkNativeModulePackage()"
  }
}
```

Windows autolinking metadata (`package.json` and `react-native.config.js`):

```json
"react-native-windows": {
  "projects": [
    {
      "directDependency": true,
      "projectFile": "windows/BrightSdkModule/BrightSdkModule.vcxproj"
    }
  ]
}
```

Published file whitelist (`files`) includes only runtime-required sources:

- `android/build.gradle`
- `android/src/main/AndroidManifest.xml`
- Java bridge/helper/package classes
- `windows/BrightSdkModule/` — vcxproj, C++ headers, sources, `.def`, and `.idl`
- `index.js`
- `react-native.config.js`

Notably excluded from package payload:

- test files,
- `.gradle` caches,
- `.brightsdk` cache files,
- generated AAR artifacts under `android/libs`,
- local `dist/` tarballs.

## Installation

### From npm tarball

```bash
npm install ./react-native-bright-sdk-2.0.3.tgz
```

### From GitHub repository

```bash
npm install git+https://github.com/BrightSDK/react-native-plugin.git
```

## Usage Example

```js
import { useEffect } from 'react';
import BrightSdk from 'react-native-bright-sdk';

export default function App() {
  useEffect(() => {
    BrightSdk.init();
  }, []);

  async function onConsentAccepted() {
    await BrightSdk.enable();
  }

  async function onConsentDeclined() {
    await BrightSdk.disable();
  }

  async function onConsentDialogShown() {
    await BrightSdk.reportConsentShown();
  }

  return null;
}
```

## Testing

The repository test suite uses Node built-in test runner (`node --test`) and validates:

- package metadata is correct (`name`, `main`, `files`, repository URL),
- `index.js` exports `BrightSdkNativeModule`,
- Android helper keeps required BrightSDK calls and settings,
- native module exposes all expected bridge methods,
- `npm pack --dry-run` includes only intended files.

Run locally:

```bash
npm test
```

Validate pack contents only:

```bash
npm run pack:check
```

## CI and Release Automation

### CI workflow (`.github/workflows/ci.yml`)

Triggered on:
- push to `main`
- pull requests

Steps:
- setup Node.js 20
- run `npm test`
- run `npm run pack:check`

### Release workflow (`.github/workflows/release.yml`)

Triggered on:
- push tags matching `*.*.*`
- manual `workflow_dispatch`

Release behavior from source:

1. Resolves version from `package.json`.
2. For tag-triggered runs, enforces `tag == package.json version`.
3. Runs tests and pack validation.
4. Builds tarball via `npm pack --pack-destination dist`.
5. Publishes GitHub Release with `dist/*.tgz` via `softprops/action-gh-release@v2`.

## Windows Native Architecture

### Bridge module

`windows/BrightSdkModule/BrightSdkNativeModule.h`

- C++/WinRT module annotated with `REACT_MODULE(BrightSdkNativeModule)`
- Dynamically loads `lum_sdk.dll` via `LoadLibraryW` at first use
- Resolves all BrightSDK C API functions by name at load time
- If the DLL is missing, SDK calls are silently skipped (app still runs)
- Exposes `REACT_METHOD` functions matching the Android bridge API, plus additional Windows-specific methods

### Package registration

`windows/BrightSdkModule/ReactPackageProvider.h` / `.cpp`

- Implements `IReactPackageProvider`
- Uses `AddAttributedModules` for automatic discovery of `REACT_MODULE`-annotated types

### SDK C API header

`windows/BrightSdkModule/lum_sdk.h`

- Declares the `__stdcall` C API surface of `lum_sdk.dll`
- Functions: `brd_sdk_init_c`, `brd_sdk_opt_in_c`, `brd_sdk_opt_out_c`, `brd_sdk_close_c`, `brd_sdk_get_uuid_c`, etc.
- Consent choice constants: `LUM_SDK_CHOICE_PEER`, `LUM_SDK_CHOICE_NOT_PEER`

### Events

- `onBrightSdkChoiceChanged` — emitted via `RCTDeviceEventEmitter` when the native SDK reports a consent choice change. Payload: `{ choice: int, isPeer: boolean }`.

## Operational Notes

- Android uses Java bridge via `ReactContextBaseJavaModule`; Windows uses C++/WinRT via `REACT_MODULE` macros.
- `initBrightSdk()` uses current activity on Android; on Windows it calls through the dynamically loaded DLL.
- Consent lifecycle should be managed by app UI (because native BrightSDK consent is skipped in helper settings).
- On Windows, if `lum_sdk.dll` is not deployed, the module disables itself silently.
- Keep package version and release tag aligned to avoid release workflow failure.

## File Map

- `index.js` - JS entrypoint exporting native module.
- `react-native.config.js` - Autolinking config for `react-native-windows`.
- `android/build.gradle` - Android library + BrightSDK Gradle wiring.
- `android/src/main/java/com/brightsdk/react/BrightSdkNativeModule.java` - React Native bridge methods.
- `android/src/main/java/com/brightsdk/react/BrightSdkNativeModulePackage.java` - module registration package.
- `android/src/main/java/com/brightsdk/react/BrightSdkHelper.java` - singleton BrightApi wrapper.
- `windows/BrightSdkModule/BrightSdkNativeModule.h` - Windows C++/WinRT bridge (REACT_METHOD functions + dynamic DLL loading).
- `windows/BrightSdkModule/ReactPackageProvider.h` / `.cpp` - Windows module registration.
- `windows/BrightSdkModule/lum_sdk.h` - C API header for BrightSDK Windows DLL.
- `windows/BrightSdkModule/BrightSdkModule.vcxproj` - Visual Studio project.
- `windows/BrightSdkModule/BrightSdkModule.def` - Module-definition file exporting `DllGetActivationFactory` for WinRT activation.
- `windows/BrightSdkModule/ReactPackageProvider.idl` - WinRT IDL for proper WinMD generation.
- `windows/BrightSdkModule/pch.h` / `.cpp` - Precompiled header.
- `tests/package.test.mjs` - package/API integrity tests.
- `.github/workflows/ci.yml` - CI checks.
- `.github/workflows/release.yml` - release pipeline.
