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
import React, {useEffect, useState} from 'react';
import {SafeAreaView, ScrollView, StyleSheet, Text, View, Pressable, Alert, Modal} from 'react-native';
import BrightSdk from 'react-native-bright-sdk';

function ActionButton({title, onPress}) {
  return (
    <Pressable style={styles.button} onPress={onPress}>
      <Text style={styles.buttonText}>{title}</Text>
    </Pressable>
  );
}

export default function App() {
  const [consentChoice, setConsentChoice] = useState('unknown');
  const [uuid, setUuid] = useState('not loaded');
  const [consentVisible, setConsentVisible] = useState(false);
  const isEnabled = consentChoice === '1';

  useEffect(() => {
    let isActive = true;

    const initSdk = async () => {
      try {
        await BrightSdk.init();
        if (isActive) {
          await refreshState();
        }
      } catch (e) {
        Alert.alert('BrightSDK init failed', String(e));
      }
    };

    initSdk();
    return () => {
      isActive = false;
    };
  }, []);

  const enableSdk = async () => {
    try {
      await BrightSdk.enable();
      await refreshState();
    } catch (e) {
      Alert.alert('Enable failed', String(e));
    }
  };

  const disableSdk = async () => {
    try {
      await BrightSdk.disable();
      await refreshState();
    } catch (e) {
      Alert.alert('Disable failed', String(e));
    }
  };

  const onConsentAccept = async () => {
    try {
      await BrightSdk.reportConsentShown();
      await enableSdk();
      setConsentVisible(false);
    } catch (e) {
      Alert.alert('Consent accept failed', String(e));
    }
  };

  const onConsentDecline = async () => {
    try {
      await BrightSdk.reportConsentShown();
      await disableSdk();
      setConsentVisible(false);
    } catch (e) {
      Alert.alert('Consent decline failed', String(e));
    }
  };

  const refreshState = async () => {
    try {
      const [choice, sdkUuid] = await Promise.all([
        BrightSdk.getConsentChoice(),
        BrightSdk.getUuid(),
      ]);
      setConsentChoice(String(choice));
      setUuid(sdkUuid || 'null');
    } catch (e) {
      Alert.alert('Failed to refresh state', String(e));
    }
  };

  return (
    <SafeAreaView style={styles.root}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>BrightSDK React Native Minimal Example</Text>
        <Text style={styles.subtitle}>Minimal flow: init, consent change, report consent shown, and state read.</Text>
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Current state</Text>
          <Text style={styles.row}>Consent: {consentChoice}</Text>
          <Text style={styles.row}>UUID: {uuid}</Text>
        </View>
        <ActionButton
          title={isEnabled ? 'Disable' : 'Enable'}
          onPress={isEnabled ? disableSdk : () => setConsentVisible(true)}
        />
        <ActionButton title="Show Consent" onPress={() => setConsentVisible(true)} />

        <Modal visible={consentVisible} animationType="slide" onRequestClose={() => setConsentVisible(false)}>
          <SafeAreaView style={styles.modalRoot}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Consent</Text>
              <Pressable onPress={() => setConsentVisible(false)}>
                <Text style={styles.modalClose}>Close</Text>
              </Pressable>
            </View>
            <View style={styles.consentWrap}>
              <Text style={styles.consentTitle}>Help Keep This App Free</Text>
              <Text style={styles.consentBody}>
                By opting in, you allow BrightSDK network sharing. You can change this anytime.
              </Text>
              <View style={styles.consentButtons}>
                <Pressable style={[styles.consentButton, styles.declineButton]} onPress={onConsentDecline}>
                  <Text style={styles.declineText}>Decline</Text>
                </Pressable>
                <Pressable style={[styles.consentButton, styles.acceptButton]} onPress={onConsentAccept}>
                  <Text style={styles.acceptText}>Accept</Text>
                </Pressable>
              </View>
            </View>
          </SafeAreaView>
        </Modal>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {flex: 1, backgroundColor: '#f3f6fb'},
  content: {padding: 20, gap: 12},
  title: {fontSize: 22, fontWeight: '700', color: '#0f1f2f'},
  subtitle: {fontSize: 14, lineHeight: 20, color: '#3a4b5c'},
  card: {padding: 14, borderRadius: 10, backgroundColor: '#ffffff', borderWidth: 1, borderColor: '#d9e3ee'},
  cardTitle: {fontSize: 16, fontWeight: '700', marginBottom: 6, color: '#0f1f2f'},
  row: {fontSize: 14, color: '#223345', marginTop: 2},
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
  consentWrap: {
    margin: 16,
    padding: 18,
    borderRadius: 14,
    backgroundColor: '#f4f8fd',
    borderWidth: 1,
    borderColor: '#d4e2f1',
  },
  consentTitle: {fontSize: 22, fontWeight: '800', color: '#0f1f2f', marginBottom: 10},
  consentBody: {fontSize: 15, lineHeight: 22, color: '#2b3c4d', marginBottom: 18},
  consentButtons: {flexDirection: 'row', gap: 10},
  consentButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  declineButton: {backgroundColor: '#ffffff', borderWidth: 1, borderColor: '#c2d4e7'},
  acceptButton: {backgroundColor: '#0f7d4f'},
  declineText: {fontSize: 14, fontWeight: '700', color: '#1f3550'},
  acceptText: {fontSize: 14, fontWeight: '700', color: '#ffffff'},
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
    "react-native-bright-sdk": "file:../.."
  },
  "devDependencies": {
    "@react-native-community/cli": "15.0.1",
    "@react-native-community/cli-platform-android": "15.0.1",
    "@react-native-community/cli-platform-ios": "15.0.1"
  }
}
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