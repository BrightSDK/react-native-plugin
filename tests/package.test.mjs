import test from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
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

test('package metadata exposes the React Native Android entry points', () => {
    assert.equal(packageJson.name, 'react-native-bright-sdk');
    assert.equal(packageJson.main, 'index.js');
    assert.deepEqual(packageJson.files, [
        'android/build.gradle',
        'android/src/main/AndroidManifest.xml',
        'android/src/main/java/com/brightsdk/react/BrightSdkHelper.java',
        'android/src/main/java/com/brightsdk/react/BrightSdkNativeModule.java',
        'android/src/main/java/com/brightsdk/react/BrightSdkNativeModulePackage.java',
        'index.js',
    ]);
    assert.equal(
        packageJson['react-native']?.android?.packageImportPath,
        'import com.brightsdk.react.BrightSdkNativeModulePackage;'
    );
    assert.equal(
        packageJson['react-native']?.android?.packageInstance,
        'new BrightSdkNativeModulePackage()'
    );
});

test('index exports the Bright native module from react-native NativeModules', () => {
    assert.match(indexSource, /import\s+\{\s*NativeModules\s*\}\s+from\s+'react-native';/);
    assert.match(indexSource, /const\s+\{\s*BrightSdkNativeModule\s*\}\s*=\s*NativeModules;/);
    assert.match(indexSource, /export\s+default\s+BrightSdkNativeModule;/);
});

test('Android helper keeps the Bright SDK lifecycle wiring intact', () => {
    assert.match(helperSource, /settings\.setSkipConsent\(true\);/);
    assert.match(helperSource, /settings\.setMinJobId\(1\);/);
    assert.match(helperSource, /settings\.setMaxJobId\(1000\);/);
    assert.match(helperSource, /BrightApi\.init\(context, settings\);/);
    assert.match(helperSource, /BrightApi\.externalOptIn\(context\);/);
    assert.match(helperSource, /BrightApi\.optOut\(context\);/);
    assert.match(helperSource, /BrightApi\.reportConsentShown\(context\);/);
});

test('Android native module exposes the public JS bridge methods', () => {
    assert.match(nativeModuleSource, /return\s+"BrightSdkNativeModule";/);
    assert.match(nativeModuleSource, /public void handleConsentChange\(boolean value, Promise promise\)/);
    assert.match(nativeModuleSource, /public void reportConsentShown\(Promise promise\)/);
    assert.match(nativeModuleSource, /public void initBrightSdk\(\)/);
    assert.match(nativeModuleSource, /brightSdkHelper\.enable\(getReactApplicationContext\(\)\);/);
    assert.match(nativeModuleSource, /brightSdkHelper\.disable\(getReactApplicationContext\(\)\);/);
    assert.match(nativeModuleSource, /brightSdkHelper\.reportConsentShown\(getReactApplicationContext\(\)\);/);
});

test('npm pack dry-run includes the published sources and excludes repository noise', () => {
    const packOutput = execFileSync('npm', ['pack', '--json', '--dry-run'], {
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
    assert(!files.has('tests/package.test.mjs'));
    assert(!files.has('android/.brightsdk/sdk_versions.json'));
    assert(!files.has('android/.gradle/workspace-id.txt'));
    assert(!files.has('android/build/reports/problems/problems-report.html'));
    assert(!files.has('android/libs/bright_sdk-1.534.679.aar'));
    assert(!Array.from(files).some((file) => file.startsWith('dist/')));
    assert(!files.has('node_modules'));
});