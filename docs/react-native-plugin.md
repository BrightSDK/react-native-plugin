# react-native-bright-sdk

GitHub: https://github.com/BrightSDK/react-native-plugin  
Package: `react-native-bright-sdk`  
Current version: `1.0.6`  
License: MIT

## Overview

`react-native-bright-sdk` is a React Native Android bridge for BrightSDK. It exposes a small JavaScript API backed by a native Android module so app code can:

- initialize BrightSDK,
- apply user consent decisions (opt-in / opt-out),
- report that consent UI was shown.

Current platform support from source:
- Android: supported
- iOS/macOS/Windows: planned (not implemented in this repository yet)

## Public JavaScript API

The package exports the Android native module directly from React Native `NativeModules`:

```js
import { NativeModules } from 'react-native';

const { BrightSdkNativeModule } = NativeModules;

export default BrightSdkNativeModule;
```

### Methods exposed to JS

From `BrightSdkNativeModule.java`:

1. `initBrightSdk(): void`
- Initializes BrightSDK using the current activity context.

2. `handleConsentChange(value: boolean): Promise<boolean>`
- `true` -> calls native enable (`BrightApi.externalOptIn(context)`)  
- `false` -> calls native disable (`BrightApi.optOut(context)`)  
- Resolves `true` on completion.

3. `reportConsentShown(): Promise<boolean>`
- Calls `BrightApi.reportConsentShown(context)`.
- Resolves `true` on completion.

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

Published file whitelist (`files`) includes only runtime-required sources:

- `android/build.gradle`
- `android/src/main/AndroidManifest.xml`
- Java bridge/helper/package classes
- `index.js`

Notably excluded from package payload:

- test files,
- `.gradle` caches,
- `.brightsdk` cache files,
- generated AAR artifacts under `android/libs`,
- local `dist/` tarballs.

## Installation

### From npm tarball

```bash
npm install ./react-native-bright-sdk-1.0.6.tgz
```

### From GitHub repository

```bash
npm install git+https://github.com/BrightSDK/react-native-plugin.git
```

## Usage Example

```js
import { useEffect } from 'react';
import BrightSdkNativeModule from 'react-native-bright-sdk';

export default function App() {
  useEffect(() => {
    BrightSdkNativeModule.initBrightSdk();
  }, []);

  async function onConsentAccepted() {
    await BrightSdkNativeModule.handleConsentChange(true);
  }

  async function onConsentDeclined() {
    await BrightSdkNativeModule.handleConsentChange(false);
  }

  async function onConsentDialogShown() {
    await BrightSdkNativeModule.reportConsentShown();
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

## Operational Notes

- This package currently bridges Android only; calling it on unsupported platforms requires platform guards in app code.
- `initBrightSdk()` uses current activity; call it when activity/app context is fully available.
- Consent lifecycle should be managed by app UI (because native BrightSDK consent is skipped in helper settings).
- Keep package version and release tag aligned to avoid release workflow failure.

## File Map

- `index.js` - JS entrypoint exporting native module.
- `android/build.gradle` - Android library + BrightSDK Gradle wiring.
- `android/src/main/java/com/brightsdk/react/BrightSdkNativeModule.java` - React Native bridge methods.
- `android/src/main/java/com/brightsdk/react/BrightSdkNativeModulePackage.java` - module registration package.
- `android/src/main/java/com/brightsdk/react/BrightSdkHelper.java` - singleton BrightApi wrapper.
- `tests/package.test.mjs` - package/API integrity tests.
- `.github/workflows/ci.yml` - CI checks.
- `.github/workflows/release.yml` - release pipeline.
