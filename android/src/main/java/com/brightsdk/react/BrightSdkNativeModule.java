package com.brightsdk.react;

import android.util.Log;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class BrightSdkNativeModule extends ReactContextBaseJavaModule {

    public BrightSdkNativeModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "BrightSdkNativeModule"; // 👈 Name exposed to JS
    }

    @ReactMethod
    public void handleConsentChange(boolean value, Promise promise) {
        Log.i(getName(), "handleConsentChange: " + value);

        BrightSdkHelper brightSdkHelper = BrightSdkHelper.getInstance();
        if (value) {
            brightSdkHelper.enable(getReactApplicationContext());
        } else {
            brightSdkHelper.disable(getReactApplicationContext());
        }

        promise.resolve(true);
    }

    @ReactMethod
    public void reportConsentShown(Promise promise) {
        Log.i(getName(), "reportConsentShown");

        BrightSdkHelper brightSdkHelper = BrightSdkHelper.getInstance();
        brightSdkHelper.reportConsentShown(getReactApplicationContext());

        promise.resolve(true);
    }

    @ReactMethod
    public void initBrightSdk() {
        BrightSdkHelper brightSdkHelper = BrightSdkHelper.getInstance();
        brightSdkHelper.init(getCurrentActivity());
    }

    @ReactMethod
    public void getConsentChoice(Promise promise) {
        Log.i(getName(), "getConsentChoice");
        BrightSdkHelper brightSdkHelper = BrightSdkHelper.getInstance();
        int choice = brightSdkHelper.getConsentChoice(getReactApplicationContext());
        promise.resolve(choice);
    }

    @ReactMethod
    public void getUuid(Promise promise) {
        Log.i(getName(), "getUuid");
        BrightSdkHelper brightSdkHelper = BrightSdkHelper.getInstance();
        String uuid = brightSdkHelper.getSdkUuid(getReactApplicationContext());
        promise.resolve(uuid);
    }

    @ReactMethod
    public void closeSdk() {
        Log.i(getName(), "closeSdk: no-op on Android");
    }
}
