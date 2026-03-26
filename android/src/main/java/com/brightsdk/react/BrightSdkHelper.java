package com.brightsdk.react;

import com.android.eapx.BrightApi;
import com.android.eapx.Settings;

import android.content.Context;
import android.app.Activity;

public class BrightSdkHelper {

    static volatile BrightSdkHelper instance = null;

    public void init(Activity activity){
        Settings settings = new Settings(activity);
        settings.setSkipConsent(true);
        settings.setMinJobId(1);
        settings.setMaxJobId(1000);
        start(activity, settings);
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
    public int getConsentChoice(Context context){
        Boolean consent = BrightApi.getConsentChoice(context);
        return Boolean.TRUE.equals(consent) ? 1 : 0;
    }
    public String getSdkUuid(Context context){
        return BrightApi.getSdkUuid();
    }

    public static synchronized BrightSdkHelper getInstance(){
        if (instance == null){
            instance = new BrightSdkHelper();
        }
        return instance;
    }
}
