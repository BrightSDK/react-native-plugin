import test from 'node:test';
import assert from 'node:assert/strict';
import { execSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..');

const readRepoFile = (...parts) =>
    readFileSync(path.join(repoRoot, ...parts), 'utf8');

const packageJson = JSON.parse(readRepoFile('package.json'));
const indexSource = readRepoFile('index.js');
const helperSource = readRepoFile('android', 'src', 'main', 'java', 'com', 'brightsdk', 'react', 'BrightSdkHelper.java');
const nativeModuleSource = readRepoFile('android', 'src', 'main', 'java', 'com', 'brightsdk', 'react', 'BrightSdkNativeModule.java');
const windowsModuleSource = readRepoFile('windows', 'BrightSdkModule', 'BrightSdkNativeModule.h');
const rnConfigSource = readRepoFile('react-native.config.js');

test('package metadata exposes the React Native Android entry points', () => {
    assert.equal(packageJson.name, 'react-native-bright-sdk');
    assert.equal(packageJson.main, 'index.js');
    assert.deepEqual(packageJson.files, [
        'android/build.gradle',
        'android/src/main/AndroidManifest.xml',
        'android/src/main/java/com/brightsdk/react/BrightSdkHelper.java',
        'android/src/main/java/com/brightsdk/react/BrightSdkNativeModule.java',
        'android/src/main/java/com/brightsdk/react/BrightSdkNativeModulePackage.java',
        'windows/BrightSdkModule/BrightSdkModule.vcxproj',
        'windows/BrightSdkModule/BrightSdkNativeModule.h',
        'windows/BrightSdkModule/ReactPackageProvider.h',
        'windows/BrightSdkModule/ReactPackageProvider.cpp',
        'windows/BrightSdkModule/lum_sdk.h',
        'windows/BrightSdkModule/pch.h',
        'windows/BrightSdkModule/pch.cpp',
        'index.js',
        'react-native.config.js',
        'windows/BrightSdkModule/ReactPackageProvider.idl',
        'windows/BrightSdkModule/BrightSdkModule.def',
    ]);
    assert.equal(packageJson.repository?.type, 'git');
    assert.equal(
        packageJson.repository?.url,
        'https://github.com/BrightSDK/react-native-plugin.git'
    );
    assert.equal(
        packageJson['react-native']?.android?.packageImportPath,
        'import com.brightsdk.react.BrightSdkNativeModulePackage;'
    );
    assert.equal(
        packageJson['react-native']?.android?.packageInstance,
        'new BrightSdkNativeModulePackage()'
    );
});

test('package metadata exposes react-native-windows autolinking config', () => {
    const rnw = packageJson['react-native-windows'];
    assert.ok(rnw, 'react-native-windows key must exist');
    assert.ok(Array.isArray(rnw.projects), 'projects must be an array');
    assert.equal(rnw.projects.length, 1);
    assert.equal(rnw.projects[0].directDependency, true);
    assert.equal(
        rnw.projects[0].projectFile,
        'windows/BrightSdkModule/BrightSdkModule.vcxproj'
    );
});

test('index exports the Bright SDK wrapper from react-native NativeModules', () => {
    assert.match(indexSource, /import\s+\{\s*NativeModules\s*\}\s+from\s+'react-native';/);
    assert.match(indexSource, /NativeModules\.BrightSdkNativeModule/);
    assert.match(indexSource, /export\s+default\s+\{/);
    assert.match(indexSource, /init:\s*\(\)\s*=>/);
    assert.match(indexSource, /enable:\s*\(\)\s*=>/);
    assert.match(indexSource, /disable:\s*\(\)\s*=>/);
    assert.match(indexSource, /reportConsentShown:\s*\(\)\s*=>/);
    assert.match(indexSource, /setAppId:\s*\(appId\)\s*=>/);
    assert.match(indexSource, /getConsentChoice:\s*\(\)\s*=>/);
    assert.match(indexSource, /getUuid:\s*\(\)\s*=>/);
    assert.match(indexSource, /close:\s*\(\)\s*=>/);
});

test('Android helper keeps the Bright SDK lifecycle wiring intact', () => {
    assert.match(helperSource, /settings\.setSkipConsent\(true\);/);
    assert.match(helperSource, /settings\.setMinJobId\(1\);/);
    assert.match(helperSource, /settings\.setMaxJobId\(1000\);/);
    assert.match(helperSource, /BrightApi\.init\(context, settings\);/);
    assert.match(helperSource, /BrightApi\.externalOptIn\(context\);/);
    assert.match(helperSource, /BrightApi\.optOut\(context\);/);
    assert.match(helperSource, /BrightApi\.reportConsentShown\(context\);/);
    assert.match(helperSource, /BrightApi\.getConsentChoice\(context\);/);
    assert.match(helperSource, /BrightApi\.getSdkUuid\(context\);/);
});

test('Android native module exposes the public JS bridge methods', () => {
    assert.match(nativeModuleSource, /return\s+"BrightSdkNativeModule";/);
    assert.match(nativeModuleSource, /public void handleConsentChange\(boolean value, Promise promise\)/);
    assert.match(nativeModuleSource, /public void reportConsentShown\(Promise promise\)/);
    assert.match(nativeModuleSource, /public void initBrightSdk\(\)/);
    assert.match(nativeModuleSource, /brightSdkHelper\.enable\(getReactApplicationContext\(\)\);/);
    assert.match(nativeModuleSource, /brightSdkHelper\.disable\(getReactApplicationContext\(\)\);/);
    assert.match(nativeModuleSource, /brightSdkHelper\.reportConsentShown\(getReactApplicationContext\(\)\);/);
    assert.match(nativeModuleSource, /public void getConsentChoice\(Promise promise\)/);
    assert.match(nativeModuleSource, /public void getUuid\(Promise promise\)/);
    assert.match(nativeModuleSource, /public void closeSdk\(\)/);
});

test('Windows native module exposes the public JS bridge methods', () => {
    assert.match(windowsModuleSource, /REACT_MODULE\(BrightSdkNativeModule/);
    assert.match(windowsModuleSource, /REACT_METHOD\(initBrightSdk/);
    assert.match(windowsModuleSource, /REACT_METHOD\(handleConsentChange/);
    assert.match(windowsModuleSource, /REACT_METHOD\(reportConsentShown/);
    assert.match(windowsModuleSource, /REACT_METHOD\(setAppId/);
    assert.match(windowsModuleSource, /REACT_METHOD\(getConsentChoice/);
    assert.match(windowsModuleSource, /REACT_METHOD\(closeSdk/);
    assert.match(windowsModuleSource, /REACT_METHOD\(getUuid/);
    assert.match(windowsModuleSource, /REACT_METHOD\(fixServiceStatus/);
});

test('Windows native module dynamically loads lum_sdk.dll', () => {
    assert.match(windowsModuleSource, /LoadLibraryW\(L"lum_sdk\.dll"\)/);
    assert.match(windowsModuleSource, /lum_sdk\.h/);
});

test('react-native.config.js wires Windows autolinking', () => {
    assert.match(rnConfigSource, /windows/);
    assert.match(rnConfigSource, /BrightSdkModule\/BrightSdkModule\.vcxproj/);
    assert.match(rnConfigSource, /directDependency:\s*true/);
});

test('npm pack dry-run includes the published sources and excludes repository noise', () => {
    const packOutput = execSync('npm pack --json --dry-run', {
        cwd: repoRoot,
        encoding: 'utf8',
    });
    const packResult = JSON.parse(packOutput);
    const files = new Set(packResult[0].files.map((file) => file.path));

    assert(files.has('package.json'));
    assert(files.has('README.md'));
    assert(files.has('index.js'));
    assert(files.has('android/build.gradle'));
    assert(files.has('android/src/main/java/com/brightsdk/react/BrightSdkHelper.java'));
    assert(files.has('windows/BrightSdkModule/BrightSdkModule.vcxproj'));
    assert(files.has('windows/BrightSdkModule/BrightSdkNativeModule.h'));
    assert(files.has('windows/BrightSdkModule/ReactPackageProvider.h'));
    assert(files.has('windows/BrightSdkModule/ReactPackageProvider.cpp'));
    assert(files.has('windows/BrightSdkModule/lum_sdk.h'));
    assert(files.has('windows/BrightSdkModule/pch.h'));
    assert(files.has('windows/BrightSdkModule/pch.cpp'));
    assert(!files.has('tests/package.test.mjs'));
    assert(!files.has('android/.brightsdk/sdk_versions.json'));
    assert(!files.has('android/.gradle/workspace-id.txt'));
    assert(!files.has('android/build/reports/problems/problems-report.html'));
    assert(!files.has('android/libs/bright_sdk-1.534.679.aar'));
    assert(!Array.from(files).some((file) => file.startsWith('dist/')));
    assert(!files.has('node_modules'));
});