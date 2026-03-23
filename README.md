# BrightSDK plugin for React-Native

[![CI](https://github.com/BrightSDK/react-native-plugin/actions/workflows/ci.yml/badge.svg)](https://github.com/BrightSDK/react-native-plugin/actions/workflows/ci.yml)
[![Release](https://github.com/BrightSDK/react-native-plugin/actions/workflows/release.yml/badge.svg)](https://github.com/BrightSDK/react-native-plugin/actions/workflows/release.yml)

A cross-platform React Native plugin that bridges the [BrightSDK](https://bright-sdk.com/) with native platform APIs. It exposes native methods for SDK initialization, consent management, and opt-in/opt-out control via a unified JavaScript API.

### Platform Support

| Platform | Status |
| -------- | ------ |
| Android  | ✅ Supported |
| Windows  | ✅ Supported |
| iOS      | 🔜 Planned |
| macOS    | 🔜 Planned |

## Table of Contents

- [Platform Support](#platform-support)
- [Why Use This Plugin](#why-use-this-plugin)
- [Requirements](#requirements)
- [Installation](#installation)
- [Platform Setup](#platform-setup)
  - [Android](#android)
  - [Windows](#windows)
  - [iOS / macOS (planned)](#ios--macos-planned)
- [Usage](#usage)
  - [Importing the Module](#importing-the-module)
  - [Initialize the SDK](#initialize-the-sdk)
  - [Handle Consent Changes](#handle-consent-changes)
  - [Report Consent Shown](#report-consent-shown)
- [API Reference](#api-reference)
- [Architecture](#architecture)
- [Building & Packing](#building--packing)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Why Use This Plugin

Integrating BrightSDK manually into a React Native app requires writing platform-specific native code, managing the bridge layer, and handling SDK lifecycle events across each target platform. This plugin eliminates that complexity:

| Concern | Manual Integration | With This Plugin |
| ------- | ------------------ | ---------------- |
| **Native bridge code** | Write and maintain `ReactContextBaseJavaModule`, method annotations, and package registration yourself | Provided out of the box — zero native code required in your app |
| **SDK lifecycle** | Call `BrightApi.init()`, `externalOptIn()`, `optOut()`, and `reportConsentShown()` directly from native code with correct context handling | Simple JS promises: `initBrightSdk()`, `handleConsentChange(bool)`, `reportConsentShown()` |
| **Gradle / build setup** | Manually add the BrightSDK Gradle plugin, configure AAR dependencies, and wire `installBrightSdk` task ordering | Handled automatically by the plugin's `build.gradle` — just install the npm package |
| **Consent management** | Implement consent skip, job ID ranges, and opt-in/opt-out flows in native code | Pre-configured defaults with a clean JS API for consent state changes |
| **Cross-platform consistency** | Re-implement the bridge for each new platform (iOS, Windows, macOS) independently | Single JS API — platform implementations are added to the plugin without changing your app code |
| **Updates & maintenance** | Track BrightSDK native API changes and update bridge code in every app | Update one npm dependency — bridge changes are absorbed by the plugin |
| **Team onboarding** | Developers need native Android/iOS knowledge to integrate or debug the SDK | Standard React Native module pattern — frontend developers can integrate without native expertise |

## Requirements

### Common

| Dependency    | Minimum Version |
| ------------- | --------------- |
| React         | >= 17.0.0       |
| React Native  | >= 0.68.0       |

### Android

| Dependency    | Minimum Version |
| ------------- | --------------- |
| Android SDK   | minSdk 21 (Android 5.0) |
| Gradle        | 8.1+            |

### iOS / macOS (planned)

| Dependency    | Minimum Version |
| ------------- | --------------- |
| iOS           | TBD             |
| macOS         | TBD             |
| Xcode         | TBD             |
| CocoaPods     | TBD             |

### Windows

| Dependency           | Minimum Version |
| -------------------- | --------------- |
| React Native Windows | >= 0.68.0       |
| Visual Studio        | 2019 (16.0+)    |
| Windows SDK          | 10.0.17763.0+   |

## Installation

### From npm tarball (local)

```bash
npm install ./path-to/react-native-bright-sdk-2.0.0.tgz
```

### From the git repository

```bash
npm install git+https://github.com/BrightSDK/react-native-plugin.git
```

## Platform Setup

### Android

#### 1. Register the native package

In your app's `MainApplication.java` (or `.kt`), add the package to the `getPackages()` list:

```java
import com.brightsdk.react.BrightSdkNativeModulePackage;

@Override
protected List<ReactPackage> getPackages() {
    List<ReactPackage> packages = new PackageList(this).getPackages();
    packages.add(new BrightSdkNativeModulePackage());
    return packages;
}
```

> **Note:** If your project uses React Native auto-linking and the `react-native` config in `package.json` is detected, this step may be handled automatically.

#### 2. Gradle configuration

The plugin's `android/build.gradle` uses the BrightSDK Gradle plugin to automatically download and install the SDK AAR. Ensure your project's root `build.gradle` can resolve `com.brightdata:bright-sdk-gradle`:

```groovy
buildscript {
    repositories {
        mavenCentral()
        google()
    }
    dependencies {
        classpath 'com.brightdata:bright-sdk-gradle:1.+'
    }
}
```

The BrightSDK AAR is placed in `android/libs/` and linked automatically at build time.

#### 3. Permissions

The SDK may require internet-related permissions. Ensure your `AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Windows

Windows support is provided via [React Native for Windows](https://microsoft.github.io/react-native-windows/) using a C++/WinRT native module that dynamically loads `lum_sdk.dll`.

#### 1. Autolinking

The plugin supports `react-native-windows` autolinking. After installing the npm package, run:

```bash
npx react-native autolink-windows
```

This registers the `BrightSdkModule` project in your app's Visual Studio solution. The `react-native.config.js` and `react-native-windows` entry in `package.json` provide the autolinking metadata.

#### 2. Deploy `lum_sdk.dll`

The native module loads `lum_sdk.dll` at runtime via `LoadLibrary`. Place the DLL next to your app's executable so it can be found at launch. If the DLL is not present the module silently disables itself — the app will still run but SDK calls will be no-ops.

#### 3. App capabilities

Ensure your app's `Package.appxmanifest` includes the `internetClient` capability:

```xml
<Capabilities>
  <Capability Name="internetClient" />
</Capabilities>
```

### iOS / macOS (planned)

Native iOS and macOS support will be added in a future release. Setup will include:

- CocoaPods or Swift Package Manager integration
- `BrightSdkNativeModule` Objective-C/Swift bridge
- `Info.plist` configuration for required permissions

## Usage

> **Note:** The JavaScript API is platform-agnostic. The same calls work across all supported platforms — only the native setup differs per platform.

### Importing the Module

```javascript
import BrightSdkNativeModule from 'react-native-bright-sdk';
```

### Initialize the SDK

Call `initBrightSdk()` once when your app starts (e.g., on the main screen mount). This initializes the underlying native BrightSDK with default settings (consent is skipped, job IDs 1–1000).

```javascript
import { useEffect } from 'react';
import BrightSdkNativeModule from 'react-native-bright-sdk';

function App() {
    useEffect(() => {
        BrightSdkNativeModule.initBrightSdk();
    }, []);

    return /* ... */;
}
```

### Handle Consent Changes

Enable or disable the SDK based on user consent. Returns a `Promise<boolean>` that resolves to `true` on success.

```javascript
// User opted in
await BrightSdkNativeModule.handleConsentChange(true);

// User opted out
await BrightSdkNativeModule.handleConsentChange(false);
```

### Report Consent Shown

Report to the SDK that the consent dialog was shown to the user. Returns a `Promise<boolean>`.

```javascript
await BrightSdkNativeModule.reportConsentShown();
```

### Full Example

```javascript
import React, { useEffect, useState } from 'react';
import { View, Button, Alert } from 'react-native';
import BrightSdkNativeModule from 'react-native-bright-sdk';

export default function App() {
    const [consentGiven, setConsentGiven] = useState(false);

    useEffect(() => {
        BrightSdkNativeModule.initBrightSdk();
    }, []);

    const showConsent = async () => {
        await BrightSdkNativeModule.reportConsentShown();
        Alert.alert(
            'Consent',
            'Do you agree to participate?',
            [
                {
                    text: 'Decline',
                    onPress: async () => {
                        await BrightSdkNativeModule.handleConsentChange(false);
                        setConsentGiven(false);
                    },
                },
                {
                    text: 'Accept',
                    onPress: async () => {
                        await BrightSdkNativeModule.handleConsentChange(true);
                        setConsentGiven(true);
                    },
                },
            ],
        );
    };

    return (
        <View>
            <Button title="Show Consent" onPress={showConsent} />
        </View>
    );
}
```

## API Reference

| Method | Parameters | Returns | Description |
| ------ | ---------- | ------- | ----------- |
| `initBrightSdk()` | _none_ | `void` | Initializes the BrightSDK on the native side. Call once at app startup. Configures default settings: skips built-in consent UI, sets job ID range 1–1000. |
| `handleConsentChange(value)` | `value: boolean` | `Promise<boolean>` | Opts the user in (`true`) or out (`false`) of the BrightSDK. Resolves to `true` on success. |
| `reportConsentShown()` | _none_ | `Promise<boolean>` | Notifies the SDK that a consent prompt was displayed to the user. Resolves to `true` on success. |
| `setAppId(appId)` | `appId: string` | `void` | Sets the application ID. Call before `initBrightSdk()`. _(Windows only)_ |
| `getConsentChoice()` | _none_ | `Promise<boolean \| null>` | Returns `true` (peer), `false` (not peer), or `null` (unknown). _(Windows only)_ |
| `closeSdk()` | _none_ | `void` | Shuts down the SDK and releases resources. _(Windows only)_ |
| `getUuid()` | _none_ | `Promise<string \| null>` | Returns the SDK-assigned UUID, or `null` if unavailable. _(Windows only)_ |
| `fixServiceStatus()` | _none_ | `void` | Attempts to repair the SDK service status. _(Windows only)_ |

## Architecture

The plugin follows a standard React Native native module pattern with a shared JS entry point and per-platform native implementations.

```
┌─────────────────────────────────────────────────┐
│  JavaScript (cross-platform)                    │
│                                                 │
│  import BrightSdkNativeModule from              │
│    'react-native-bright-sdk'                    │
│                                                 │
│  BrightSdkNativeModule.initBrightSdk()          │
│  BrightSdkNativeModule.handleConsentChange(val) │
│  BrightSdkNativeModule.reportConsentShown()     │
└────────┬──────────────┬──────────────┬──────────┘
         │              │              │
    ┌────▼────┐   ┌─────▼─────┐  ┌─────▼──────┐
    │ Android │   │ iOS/macOS │  │  Windows   │
    │ (Java)  │   │ (planned) │  │ (C++/WinRT)│
    └────┬────┘   └───────────┘  └─────┬──────┘
         │  React Native Bridge
┌────────▼────────────────────────────────────────┐
│  BrightSdkNativeModule.java                     │
│  (ReactContextBaseJavaModule)                   │
│                                                 │
│  @ReactMethod annotated methods exposed to JS   │
│  Delegates to BrightSdkHelper singleton         │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│  BrightSdkHelper.java (Singleton)               │
│                                                 │
│  init()   → BrightApi.init(context, settings)   │
│  enable() → BrightApi.externalOptIn(context)    │
│  disable()→ BrightApi.optOut(context)           │
│  reportConsentShown()                           │
│           → BrightApi.reportConsentShown(ctx)   │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│  BrightSDK AAR (com.android.eapx.BrightApi)     │
│  Native Android SDK                             │
└─────────────────────────────────────────────────┘
```

### Key Files

| File | Purpose |
| ---- | ------- |
| `index.js` | Entry point — exports the `BrightSdkNativeModule` native module |
| `android/build.gradle` | Android library config; applies the BrightSDK Gradle plugin |
| `android/src/main/java/.../BrightSdkNativeModule.java` | React Native bridge — exposes `@ReactMethod` functions to JS |
| `android/src/main/java/.../BrightSdkNativeModulePackage.java` | Registers the native module with React Native |
| `android/src/main/java/.../BrightSdkHelper.java` | Singleton wrapper around the BrightSDK native API |
| `windows/BrightSdkModule/BrightSdkNativeModule.h` | Windows C++/WinRT bridge — exposes `REACT_METHOD` functions to JS, dynamically loads `lum_sdk.dll` |
| `windows/BrightSdkModule/ReactPackageProvider.h/.cpp` | Registers the Windows native module with React Native |
| `windows/BrightSdkModule/lum_sdk.h` | C API header for the BrightSDK Windows DLL |
| `windows/BrightSdkModule/BrightSdkModule.vcxproj` | Visual Studio project for the native module |
| `react-native.config.js` | Autolinking configuration for `react-native-windows` |
| `ios/` _(planned)_ | iOS/macOS native module implementation |

## Building & Packing

To create a distributable `.tgz` package:

```bash
npm run pack
```

This runs `npm pack` and moves the resulting tarball to the `dist/` directory.

## Testing & Automation

Run the repository test suite locally with:

```bash
npm test
```

Validate the published package contents without generating a tarball file with:

```bash
npm run pack:check
```

The published package excludes local Android caches, build outputs, bundled AAR artifacts, and the repository test directory so release tarballs stay deterministic.

GitHub Actions workflows are included for:

- `CI`: runs on pushes to `main` and on pull requests, executing the test suite and package validation.
- `Release`: runs on tags matching `*.*.*`, or manually via workflow dispatch, and creates a GitHub Release with the generated `.tgz` asset attached.

Recommended release flow:

1. Update `package.json` to the next version and merge that change to `main`.
2. Either push a matching numeric tag such as `1.0.7`, or run the `Release` workflow manually from `main`.
3. The workflow verifies that tag-triggered releases match `package.json`, runs the test suite, validates the package payload, and uploads the generated `.tgz` asset to the GitHub Release.

## Troubleshooting

### Android

| Issue | Solution |
| ----- | -------- |
| `BrightSdkNativeModule is null` | Ensure the package is registered in `MainApplication.java` and rebuild the app. |
| SDK AAR not found | Run `./gradlew installBrightSdk` in the `android/` folder, or ensure `mavenCentral()` is in your repositories. |
| `minSdkVersion` conflict | This library requires `minSdkVersion 21`. Align your app's `minSdkVersion` accordingly. |
| Gradle plugin resolution error | Verify `com.brightdata:bright-sdk-gradle:1.+` is accessible from your build script repositories. |

### Windows

| Issue | Solution |
| ----- | -------- |
| `BrightSdkNativeModule` not found | Run `npx react-native autolink-windows` and rebuild the solution. |
| SDK calls are no-ops | `lum_sdk.dll` is missing. Place it next to your app executable. |
| Build errors in `BrightSdkModule.vcxproj` | Ensure you have the Windows 10 SDK (10.0.17763.0+) and `react-native-windows` installed. |

### General (all platforms)

| Issue | Solution |
| ----- | -------- |
| Module not found at import | Verify the package is installed: `npm ls react-native-bright-sdk`. |
| Method calls throw "not implemented" | The native module for this platform is not yet available. Check [Platform Support](#platform-support). |

## License

MIT
