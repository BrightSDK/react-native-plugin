#!/usr/bin/env bash
set -euo pipefail

APP_NAME="BrightSdkExampleApp"
RN_VERSION="0.81.0"
SKIP_INSTALL="0"
CLEAN_NATIVE="0"
CLEAN_ALL="0"

for arg in "$@"; do
  case "$arg" in
    --skip-install)
      SKIP_INSTALL="1"
      ;;
    --clean-native)
      CLEAN_NATIVE="1"
      ;;
    --clean-all)
      CLEAN_ALL="1"
      ;;
    --help|-h)
      cat <<'EOF'
Usage: bash ./example/scaffold.sh [--skip-install] [--clean-native] [--clean-all]

Creates/updates a React Native sample in example/react-native-app.

Options:
  --skip-install   Skip dependency install during React Native init.
  --clean-native   Remove existing android/ios and config files before copy.
  --clean-all      Remove all generated example artifacts and exit.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT_DIR/react-native-app"
GEN_DIR="$ROOT_DIR/.scaffold-generated"

if [[ "$CLEAN_ALL" == "1" ]]; then
  rm -rf "$APP_DIR" "$GEN_DIR"
  echo "Removed generated example artifacts."
  exit 0
fi

rm -rf "$GEN_DIR"
mkdir -p "$APP_DIR/src"

echo "Scaffolding React Native project in $APP_DIR"
if [[ "$SKIP_INSTALL" == "1" ]]; then
  npx @react-native-community/cli init "$APP_NAME" --directory "$GEN_DIR" --version "$RN_VERSION" --skip-install
else
  npx @react-native-community/cli init "$APP_NAME" --directory "$GEN_DIR" --version "$RN_VERSION"
fi

if [[ "$CLEAN_NATIVE" == "1" ]]; then
  rm -rf "$APP_DIR/android" "$APP_DIR/ios"
  rm -f "$APP_DIR/babel.config.js" "$APP_DIR/metro.config.js" "$APP_DIR/jest.config.js" "$APP_DIR/react-native.config.js"
fi

cp -R "$GEN_DIR"/android "$APP_DIR/"
cp -R "$GEN_DIR"/ios "$APP_DIR/"
cp "$GEN_DIR"/babel.config.js "$APP_DIR/"
cp "$GEN_DIR"/metro.config.js "$APP_DIR/"
cp "$GEN_DIR"/jest.config.js "$APP_DIR/"
if [[ -f "$GEN_DIR/react-native.config.js" ]]; then
  cp "$GEN_DIR"/react-native.config.js "$APP_DIR/"
fi

cat > "$APP_DIR/android/gradle/wrapper/gradle-wrapper.properties" <<'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.13-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

cat > "$APP_DIR/android/build.gradle" <<'EOF'
buildscript {
  ext {
    minSdkVersion = 24
    compileSdkVersion = 33
    targetSdkVersion = 33
    buildToolsVersion = "35.0.1"
    ndkVersion = "27.1.12297006"
    kotlinVersion = "2.1.20"
  }
  repositories {
    google()
    mavenCentral()
    maven { url 'https://jitpack.io' }
    mavenLocal()
  }
  dependencies {
    classpath('com.android.tools.build:gradle:8.8.0')
    classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:${kotlinVersion}")
  }
}

plugins {
  id 'com.facebook.react.rootproject'
}

allprojects {
  repositories {
    google()
    mavenCentral()
    maven { url 'https://jitpack.io' }
    mavenLocal()
  }
}
EOF

cat > "$APP_DIR/android/settings.gradle" <<'EOF'
pluginManagement { includeBuild("../node_modules/@react-native/gradle-plugin") }
plugins { id("com.facebook.react.settings") }
extensions.configure(com.facebook.react.ReactSettingsExtension){ ex -> ex.autolinkLibrariesFromCommand() }
rootProject.name = 'BrightSdkExampleApp'
include ':app'
includeBuild('../node_modules/@react-native/gradle-plugin')
EOF

cat > "$APP_DIR/android/gradle.properties" <<'EOF'
# Project-wide Gradle settings.

# IDE (e.g. Android Studio) users:
# Gradle settings configured through the IDE *will override*
# any settings specified in this file.

# For more details on how to configure your build environment visit
# http://www.gradle.org/docs/current/userguide/build_environment.html

# Specifies the JVM arguments used for the daemon process.
# The setting is particularly useful for tweaking memory settings.
# Default value: -Xmx512m -XX:MaxMetaspaceSize=256m
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m

# When configured, Gradle will run in incubating parallel mode.
# This option should only be used with decoupled projects. More details, visit
# http://www.gradle.org/docs/current/userguide/multi_project_builds.html#sec:decoupled_projects
# org.gradle.parallel=true

# AndroidX package structure to make it clearer which packages are bundled with the
# Android operating system, and which are packaged with your app's APK
# https://developer.android.com/topic/libraries/support-library/androidx-rn
android.useAndroidX=true
# Automatically convert third-party libraries to use AndroidX
android.enableJetifier=true

# Use this property to specify which architecture you want to build.
# You can also override it from the CLI using
# ./gradlew <task> -PreactNativeArchitectures=x86_64
reactNativeArchitectures=armeabi-v7a,arm64-v8a,x86,x86_64

# Use this property to enable support to the new architecture.
# This will allow you to use TurboModules and the Fabric render in
# your application. You should enable this flag either if you want
# to write custom TurboModules/Fabric components OR use libraries that
# are providing them.
newArchEnabled=true

# Use this property to enable or disable the Hermes JS engine.
# If set to false, you will be using JSC instead.
hermesEnabled=true
EOF

cat > "$APP_DIR/android/app/build.gradle" <<'EOF'
apply plugin: "com.android.application"
apply plugin: "org.jetbrains.kotlin.android"
apply plugin: "com.facebook.react"

/**
 * This is the configuration block to customize your React Native Android app.
 * By default you don't need to apply any configuration, just uncomment the lines you need.
 */
react {
  /* Folders */
  //   The root of your project, i.e. where "package.json" lives. Default is '..'
  // root = file("../")
  //   The folder where the react-native NPM package is. Default is ../node_modules/react-native
  // reactNativeDir = file("../node_modules/react-native")
  //   The folder where the react-native Codegen package is. Default is ../node_modules/@react-native/codegen
  // codegenDir = file("../node_modules/@react-native/codegen")
  //   The cli.js file which is the React Native CLI entrypoint. Default is ../node_modules/react-native/cli.js
  // cliFile = file("../node_modules/react-native/cli.js")

  /* Variants */
  // debuggableVariants = ["liteDebug", "prodDebug"]

  /* Bundling */
  // nodeExecutableAndArgs = ["node"]
  // bundleCommand = "ram-bundle"
  // bundleConfig = file(../rn-cli.config.js)
  // bundleAssetName = "MyApplication.android.bundle"
  // entryFile = file("../js/MyApplication.android.js")
  // extraPackagerArgs = []

  /* Hermes Commands */
  // hermesCommand = "$rootDir/my-custom-hermesc/bin/hermesc"
  // hermesFlags = ["-O", "-output-source-map"]

  /* Autolinking */
  autolinkLibrariesWithApp()
}

def enableProguardInReleaseBuilds = false

def jscFlavor = 'org.webkit:android-jsc:+'

android {
  ndkVersion rootProject.ext.ndkVersion
  buildToolsVersion rootProject.ext.buildToolsVersion
  compileSdk 35

  namespace "com.brightsdkexampleapp"
  defaultConfig {
    applicationId "com.brightsdkexampleapp"
    minSdkVersion rootProject.ext.minSdkVersion
    targetSdkVersion rootProject.ext.targetSdkVersion
    versionCode 1
    versionName "1.0"
  }
  signingConfigs {
    debug {
      storeFile file('debug.keystore')
      storePassword 'android'
      keyAlias 'androiddebugkey'
      keyPassword 'android'
    }
  }
  buildTypes {
    debug {
      signingConfig signingConfigs.debug
    }
    release {
      signingConfig signingConfigs.debug
      minifyEnabled enableProguardInReleaseBuilds
      proguardFiles getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro"
    }
  }
}

dependencies {
  implementation("com.facebook.react:react-android")

  if (hermesEnabled.toBoolean()) {
    implementation("com.facebook.react:hermes-android")
  } else {
    implementation jscFlavor
  }
}
EOF

cat > "$APP_DIR/android/app/src/main/java/com/brightsdkexampleapp/MainApplication.kt" <<'EOF'
package com.brightsdkexampleapp

import android.app.Application
import com.facebook.react.PackageList
import com.facebook.react.ReactApplication
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactPackage
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint.load
import com.facebook.react.defaults.DefaultReactHost.getDefaultReactHost
import com.facebook.react.defaults.DefaultReactNativeHost
import com.facebook.react.soloader.OpenSourceMergedSoMapping
import com.facebook.soloader.SoLoader

class MainApplication : Application(), ReactApplication {

  override val reactNativeHost: ReactNativeHost =
      object : DefaultReactNativeHost(this) {
        override fun getPackages(): List<ReactPackage> =
            PackageList(this).packages.apply {
              // Packages that cannot be autolinked yet can be added manually here, for example:
              // add(MyReactNativePackage())
            }

        override fun getJSMainModuleName(): String = "index"

        override fun getUseDeveloperSupport(): Boolean = BuildConfig.DEBUG

        override val isNewArchEnabled: Boolean = BuildConfig.IS_NEW_ARCHITECTURE_ENABLED
        override val isHermesEnabled: Boolean = BuildConfig.IS_HERMES_ENABLED
      }

  override val reactHost: ReactHost
    get() = getDefaultReactHost(applicationContext, reactNativeHost)

  override fun onCreate() {
    super.onCreate()
    SoLoader.init(this, OpenSourceMergedSoMapping)
    if (BuildConfig.IS_NEW_ARCHITECTURE_ENABLED) {
      // If you opted-in for the New Architecture, we load the native entry point for this app.
      load()
    }
  }
}
EOF

cat > "$APP_DIR/metro.config.js" <<'EOF'
const path = require('path');
const {getDefaultConfig, mergeConfig} = require('@react-native/metro-config');

const projectRoot = __dirname;
const pluginRoot = path.resolve(projectRoot, '../..');

module.exports = mergeConfig(getDefaultConfig(projectRoot), {
  watchFolders: [pluginRoot],
  resolver: {
    disableHierarchicalLookup: true,
    extraNodeModules: {
      'react-native-bright-sdk': pluginRoot,
    },
    nodeModulesPaths: [
      path.resolve(projectRoot, 'node_modules'),
    ],
  },
});
EOF

cat > "$APP_DIR/index.js" <<'EOF'
import {AppRegistry} from 'react-native';
import App from './src/App';

AppRegistry.registerComponent('BrightSdkExampleApp', () => App);
EOF

cat > "$APP_DIR/app.json" <<'EOF'
{
  "name": "BrightSdkExampleApp",
  "displayName": "BrightSdkExampleApp"
}
EOF

cat > "$APP_DIR/src/App.js" <<'EOF'
import React, {useEffect, useState, useCallback} from 'react';
import {SafeAreaView, ScrollView, StyleSheet, Text, View, Pressable, Alert} from 'react-native';
import BrightSdk from 'react-native-bright-sdk';

function ActionButton({title, onPress, color}) {
  return (
    <Pressable style={[styles.button, color && {backgroundColor: color}]} onPress={onPress}>
      <Text style={styles.buttonText}>{title}</Text>
    </Pressable>
  );
}

export default function App() {
  const [consentChoice, setConsentChoice] = useState(null);
  const [uuid, setUuid] = useState(null);
  const [consentVisible, setConsentVisible] = useState(false);
  const isEnabled = consentChoice === true;

  const refreshState = useCallback(async () => {
    try {
      const choice = await BrightSdk.getConsentChoice();
      const sdkUuid = await BrightSdk.getUuid();
      setConsentChoice(choice);
      setUuid(sdkUuid || null);
    } catch (_) {}
  }, []);

  useEffect(() => {
    let active = true;
    (async () => {
      await BrightSdk.init();
      if (active) await refreshState();
    })();
    return () => { active = false; };
  }, [refreshState]);

  useEffect(() => {
    const sub = BrightSdk.onChoiceChanged((event) => {
      setConsentChoice(event.isPeer);
      refreshState();
    });
    return () => sub?.remove?.();
  }, [refreshState]);

  const enableSdk = async () => {
    setConsentChoice(true);
    await BrightSdk.enable();
    await refreshState();
  };

  const disableSdk = async () => {
    setConsentChoice(false);
    await BrightSdk.disable();
    await refreshState();
  };

  const handleAccept = async () => {
    await BrightSdk.reportConsentShown();
    await enableSdk();
    setConsentVisible(false);
  };

  const handleDecline = async () => {
    await BrightSdk.reportConsentShown();
    await disableSdk();
    setConsentVisible(false);
  };

  if (consentVisible) {
    return (
      <SafeAreaView style={styles.modalRoot}>
        <View style={styles.modalHeader}>
          <Text style={styles.modalTitle}>Consent</Text>
          <Pressable onPress={() => setConsentVisible(false)}>
            <Text style={styles.modalClose}>Close</Text>
          </Pressable>
        </View>
        <View style={styles.webviewFallback}>
          <Text style={styles.fallbackTitle}>BrightSDK Consent</Text>
          <Text style={styles.fallbackText}>
            This app uses BrightSDK. By accepting, you agree to let the SDK
            operate in the background. You can change this at any time.
          </Text>
          <ActionButton title="Accept" onPress={handleAccept} />
          <ActionButton title="Decline" onPress={handleDecline} />
        </View>
      </SafeAreaView>
    );
  }

  const statusText = consentChoice === null ? 'Unknown' : isEnabled ? 'Enabled' : 'Disabled';

  return (
    <SafeAreaView style={styles.root}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>BrightSDK React Native Example</Text>
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Status</Text>
          <Text style={[styles.status, {color: isEnabled ? '#1a8f3c' : '#8f1a1a'}]}>{statusText}</Text>
          {uuid && <Text style={styles.uuid}>UUID: {uuid}</Text>}
        </View>
        <ActionButton
          title={isEnabled ? 'Disable' : 'Enable'}
          color={isEnabled ? '#c0392b' : '#27ae60'}
          onPress={isEnabled ? disableSdk : () => setConsentVisible(true)}
        />
        <ActionButton title="Show Consent" onPress={() => setConsentVisible(true)} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {flex: 1, backgroundColor: '#f3f6fb'},
  content: {padding: 20, gap: 12},
  title: {fontSize: 22, fontWeight: '700', color: '#0f1f2f'},
  card: {padding: 14, borderRadius: 10, backgroundColor: '#ffffff', borderWidth: 1, borderColor: '#d9e3ee'},
  cardTitle: {fontSize: 14, fontWeight: '600', color: '#6b7b8d', marginBottom: 4},
  status: {fontSize: 22, fontWeight: '700'},
  uuid: {fontSize: 12, color: '#6b7b8d', marginTop: 6, fontFamily: 'monospace'},
  button: {backgroundColor: '#115e9b', paddingVertical: 12, paddingHorizontal: 14, borderRadius: 10},
  buttonText: {color: '#ffffff', fontWeight: '700', fontSize: 14, textAlign: 'center'},
  modalRoot: {flex: 1, backgroundColor: '#ffffff'},
  modalHeader: {
    height: 52,
    paddingHorizontal: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#d9e3ee',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  modalTitle: {fontSize: 16, fontWeight: '700', color: '#0f1f2f'},
  modalClose: {fontSize: 14, fontWeight: '600', color: '#115e9b'},
  webviewFallback: {flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20, gap: 12},
  fallbackTitle: {fontSize: 20, fontWeight: '700', color: '#0f1f2f', marginBottom: 8},
  fallbackText: {fontSize: 15, color: '#3a4b5c', textAlign: 'center', lineHeight: 22, marginBottom: 16},
});
EOF

cat > "$APP_DIR/package.json" <<'EOF'
{
  "name": "react-native-bright-sdk-example",
  "version": "1.0.0",
  "private": true,
  "description": "Minimal React Native app demonstrating react-native-bright-sdk integration",
  "main": "index.js",
  "scripts": {
    "start": "react-native start",
    "android": "react-native run-android",
    "ios": "react-native run-ios",
    "windows": "react-native run-windows",
    "setup": "bash ../scaffold.sh --skip-install && npm install",
    "clean": "bash ../scaffold.sh --clean-all"
  },
  "dependencies": {
    "@react-native/metro-config": "0.81.0",
    "@react-native/virtualized-lists": "0.81.0",
    "react": "19.1.0",
    "react-native": "0.81.0",
    "react-native-bright-sdk": "file:../..",
    "react-native-windows": "0.81.9"
  },
  "devDependencies": {
    "@react-native-community/cli": "15.0.1",
    "@react-native-community/cli-platform-android": "15.0.1",
    "@react-native-community/cli-platform-ios": "15.0.1"
  }
}
EOF

cat > "$APP_DIR/.npmrc" <<'EOF'
legacy-peer-deps=true
EOF

rm -rf "$GEN_DIR"

# Ensure example/brightsdk/ directory exists for SDK binaries.
# Users must place lum_sdk.dll (and optionally brd_config.json) here.
# The Windows .vcxproj copies these to the build output at build time.
SDK_DIR="$ROOT_DIR/brightsdk"
mkdir -p "$SDK_DIR"
if [[ ! -f "$SDK_DIR/lum_sdk.dll" ]]; then
  echo ""
  echo "NOTE: Place BrightSDK binaries in example/brightsdk/"
  echo "  Required: lum_sdk.dll (matching your target architecture)"
  echo "  Optional: brd_config.json"
  echo "  Without lum_sdk.dll, SDK calls will be no-ops at runtime."
fi

echo "Scaffold complete."
echo "Next steps:"
echo "  npm --prefix ./example/react-native-app install"
echo "  npm --prefix ./example/react-native-app run start"
echo "  npm --prefix ./example/react-native-app run android"
echo ""
echo "Windows (run on Windows):"
echo "  cd example/react-native-app"
echo "  npx react-native-windows-init --overwrite --namespace BrightSdkExampleApp"
echo "  react-native run-windows"