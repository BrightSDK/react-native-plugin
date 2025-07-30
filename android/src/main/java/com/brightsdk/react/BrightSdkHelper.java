package com.brightsdk.react;

import com.android.eapx.BrightApi;
import com.android.eapx.Settings;

import android.content.Context;

public class BrightSdkHelper {

    static volatile BrightSdkHelper instance = null;

    public void init(Context context){
        Settings settings = new Settings(context);
        settings.setSkipConsent(true);
        settings.setMinJobId(1);
        settings.setMaxJobId(1000);
        start(context, settings);
    }

    public void start(Context context, Settings settings){
        BrightApi.init(context, settings);
    }
    public void enable(Context context){
        BrightApi.externalOptIn(context);
    }
    public void disable(Context context){
        BrightApi.optOut(context);
    }
    public void reportConsentShown(Context context){
        BrightApi.reportConsentShown(context);
    }

    public static synchronized BrightSdkHelper getInstance(Context context){
        if (instance == null){
            instance = new BrightSdkHelper();
            instance.init(context);
        }
        return instance;
    }
}
