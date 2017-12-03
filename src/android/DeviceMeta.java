package com.ozexpert.devicemeta;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager.NameNotFoundException;
import android.net.wifi.WifiManager;
import android.telephony.TelephonyManager;
import android.media.AudioManager;
import android.os.Build;
import android.os.Process;
import android.provider.Settings;
import java.io.File;

import java.util.Formatter;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.ozexpert.devicemeta.Utils;

/**
 * This class echoes a string called from JavaScript.
 */
public class DeviceMeta extends CordovaPlugin {

    private static Context ctx;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        ctx = this.cordova.getActivity().getApplicationContext();

        if (action.equals("getDeviceMeta")) {
            
            JSONObject r = new JSONObject();
            r.put("debug", this.isDebug());
            r.put("development", this.isDevelopment());
            r.put("root", this.isDeviceRooted());
            r.put("networkProvider", this.getNetworkProvider());
            r.put("ip", this.getIpAddress());
            r.put("manufacturer", this.getManufacturer());
            r.put("DNDMode",this.getDNDMode());

            callbackContext.success(r);
        } else {
            return false;
        }
        return true;
    }


    private boolean isDeviceRooted() {
        return checkBuildTags() || checkSuperUserApk() || checkFilePath();
    }
    private boolean checkBuildTags() {
        String buildTags = android.os.Build.TAGS;
        return buildTags != null && buildTags.contains("test-keys");
    }

    private boolean checkSuperUserApk() {
        return new File("/system/app/Superuser.apk").exists();
    }

    private boolean checkFilePath() {
        String[] paths = { "/sbin/su", "/system/bin/su", "/system/xbin/su", "/data/local/xbin/su", "/data/local/bin/su", "/system/sd/xbin/su",
                "/system/bin/failsafe/su", "/data/local/su" };
        for (String path : paths) {
            if (new File(path).exists()) return true;
        }
        return false;
    }

    private boolean isDebug() {
        try {
            if ((ctx.getPackageManager().getPackageInfo(
                ctx.getPackageName(), 0).applicationInfo.flags & 
                ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
                //Debug and development mode
                return true;
            }
        } catch (NameNotFoundException e){
            // do nothing
        }
        return false;
    }


    private boolean isDevelopment() {
        if(!Settings.Secure.getString(this.cordova.getActivity().getContentResolver(), Settings.Global.DEVELOPMENT_SETTINGS_ENABLED).equals("0"))
        {
            return true;
        }
        else
        {
            return false;
        }
        
    }

    private String getIpAddress() {
        return Utils.getIPAddress(true);
    }

    private String getNetworkProvider() {
        TelephonyManager tm = (TelephonyManager) ctx.getSystemService(Context.TELEPHONY_SERVICE);
        return tm.getNetworkOperatorName();
    }
    
    private int getDNDMode() {
        AudioManager am = (AudioManager) ctx.getSystemService(Context.AUDIO_SERVICE);
        return am.getRingerMode(); 
    }

    private String getManufacturer() {
        return Build.MANUFACTURER;
    }

    // private void getDeviceMeta(String message, CallbackContext callbackContext) {
    //     if (message != null && message.length() > 0) {
    //         callbackContext.success(message);
    //     } else {
    //         callbackContext.error("Expected one non-empty string argument.");
    //     }
    // }
}
