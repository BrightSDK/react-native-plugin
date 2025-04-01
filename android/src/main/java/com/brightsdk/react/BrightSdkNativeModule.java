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
}
