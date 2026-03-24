#pragma once

#include "NativeModules.h"
#include <winrt/Microsoft.ReactNative.h>
#include <string>
#include <fstream>
#include <chrono>
#include <shlobj.h>

// BrightSDK C API � loaded dynamically so the app can run without lum_sdk.dll.
#include "lum_sdk.h"

namespace BrightSdk {


// File logger � writes timestamped entries to %LOCALAPPDATA%\BoostNet\Logs\brightsdk.log
// Also forwards to OutputDebugStringW for debugger visibility.
inline void LogToFile(const wchar_t *msg) {
  OutputDebugStringW(msg);
  static std::wofstream s_log;
  if (!s_log.is_open()) {
    // Use LOCALAPPDATA � in MSIX this resolves to the package's LocalCache/Local
    wchar_t buf[MAX_PATH] = {};
    DWORD len = GetEnvironmentVariableW(L"TEMP", buf, MAX_PATH);
    if (len > 0 && len < MAX_PATH) {
      std::wstring base(buf);
      CreateDirectoryW((base + L"\\BoostNet").c_str(), nullptr);
      CreateDirectoryW((base + L"\\BoostNet\\Logs").c_str(), nullptr);
      s_log.open(base + L"\\BoostNet\\Logs\\brightsdk.log", std::ios::app);
    }
  }
  if (s_log.is_open()) {
    auto now = std::chrono::system_clock::now();
    auto t = std::chrono::system_clock::to_time_t(now);
    wchar_t timeBuf[32] = {};
    struct tm lt;
    localtime_s(&lt, &t);
    wcsftime(timeBuf, 32, L"%Y-%m-%d %H:%M:%S", &lt);
    s_log << timeBuf << L" " << msg;
    s_log.flush();
  }
}

// Thin dynamic-load wrapper around lum_sdk.dll so the app still launches when
// the SDK binary has not been deployed yet (dev builds, CI, etc.).
struct BrightSdkLib {
  HMODULE hMod = nullptr;

  // Function pointers matching the C API declared in lum_sdk.h.
  // All SDK functions use WINAPI (__stdcall) calling convention.
  decltype(&brd_sdk_is_supported_c)              is_supported = nullptr;
  decltype(&brd_sdk_set_appid_c)                 set_appid = nullptr;
  decltype(&brd_sdk_set_choice_change_cb_c)      set_choice_change_cb = nullptr;
  decltype(&brd_sdk_set_service_status_change_cb_c) set_service_status_cb = nullptr;
  decltype(&brd_sdk_set_skip_consent_on_init_c)  set_skip_consent = nullptr;
  decltype(&brd_sdk_init_c)                      init = nullptr;
  decltype(&brd_sdk_close_c)                     close = nullptr;
  decltype(&brd_sdk_show_consent_c)              show_consent = nullptr;
  decltype(&brd_sdk_opt_out_c)                   opt_out = nullptr;
  decltype(&brd_sdk_opt_in_c)                    opt_in = nullptr;
  decltype(&brd_sdk_get_consent_choice_c)        get_consent_choice = nullptr;
  decltype(&brd_sdk_get_uuid_c)                  get_uuid = nullptr;
  decltype(&brd_sdk_fix_service_status_c)        fix_service_status = nullptr;

  bool loaded() const { return hMod != nullptr; }

  bool Load() {
    hMod = LoadLibraryW(L"lum_sdk.dll");
    if (!hMod) {
      LogToFile(L"[BrightSDK] lum_sdk.dll not found � SDK disabled\n");
      return false;
    }
    auto get = [&](const char *name) { return GetProcAddress(hMod, name); };

    is_supported          = reinterpret_cast<decltype(is_supported)>(get("brd_sdk_is_supported_c"));
    set_appid             = reinterpret_cast<decltype(set_appid)>(get("brd_sdk_set_appid_c"));
    set_choice_change_cb  = reinterpret_cast<decltype(set_choice_change_cb)>(get("brd_sdk_set_choice_change_cb_c"));
    set_service_status_cb = reinterpret_cast<decltype(set_service_status_cb)>(get("brd_sdk_set_service_status_change_cb_c"));
    set_skip_consent      = reinterpret_cast<decltype(set_skip_consent)>(get("brd_sdk_set_skip_consent_on_init_c"));
    init                  = reinterpret_cast<decltype(init)>(get("brd_sdk_init_c"));
    close                 = reinterpret_cast<decltype(close)>(get("brd_sdk_close_c"));
    show_consent          = reinterpret_cast<decltype(show_consent)>(get("brd_sdk_show_consent_c"));
    opt_out               = reinterpret_cast<decltype(opt_out)>(get("brd_sdk_opt_out_c"));
    opt_in                = reinterpret_cast<decltype(opt_in)>(get("brd_sdk_opt_in_c"));
    get_consent_choice    = reinterpret_cast<decltype(get_consent_choice)>(get("brd_sdk_get_consent_choice_c"));
    get_uuid              = reinterpret_cast<decltype(get_uuid)>(get("brd_sdk_get_uuid_c"));
    fix_service_status    = reinterpret_cast<decltype(fix_service_status)>(get("brd_sdk_fix_service_status_c"));

    LogToFile(L"[BrightSDK] lum_sdk.dll loaded successfully\n");
    return true;
  }

  void Unload() {
    if (hMod) {
      FreeLibrary(hMod);
      hMod = nullptr;
    }
  }
};

inline BrightSdkLib &GetBrightSdkLib() {
  static BrightSdkLib lib;
  return lib;
}

REACT_MODULE(BrightSdkNativeModule, L"BrightSdkNativeModule")
struct BrightSdkNativeModule {
  REACT_INIT(Initialize)
  void Initialize(winrt::Microsoft::ReactNative::ReactContext const &ctx) noexcept {
    m_context = ctx;
    s_instance = this;
    LogToFile(L"[BrightSDK] Module initialized\n");
  }

  ~BrightSdkNativeModule() {
    if (s_instance == this)
      s_instance = nullptr;
  }

  // Matches Android: BrightSdkNativeModule.initBrightSdk()
  REACT_METHOD(initBrightSdk, L"initBrightSdk")
  void initBrightSdk() noexcept {
    auto &lib = GetBrightSdkLib();
    if (!lib.loaded() && !lib.Load()) {
      LogToFile(L"[BrightSDK] initBrightSdk: SDK not available\n");
      return;
    }

    if (lib.is_supported && !lib.is_supported()) {
      LogToFile(L"[BrightSDK] initBrightSdk: platform not supported\n");
      return;
    }

    if (lib.set_choice_change_cb)
      lib.set_choice_change_cb(OnChoiceChanged);

    if (lib.set_skip_consent)
      lib.set_skip_consent(TRUE);

    if (lib.init)
      lib.init();

    LogToFile(L"[BrightSDK] initBrightSdk: initialized\n");
  }

  // Set the application ID. Should be called before initBrightSdk().
  REACT_METHOD(setAppId, L"setAppId")
  void setAppId(std::string appId) noexcept {
    auto &lib = GetBrightSdkLib();
    if (!lib.loaded() && !lib.Load()) return;
    if (lib.set_appid) {
      std::vector<char> buf(appId.begin(), appId.end());
      buf.push_back('\0');
      lib.set_appid(buf.data());
    }
  }

  // Matches Android: BrightSdkNativeModule.handleConsentChange(bool)
  REACT_METHOD(handleConsentChange, L"handleConsentChange")
  void handleConsentChange(bool value) noexcept {
    auto &lib = GetBrightSdkLib();
    if (!lib.loaded()) return;

    if (value) {
      if (lib.opt_in) lib.opt_in();
      LogToFile(L"[BrightSDK] handleConsentChange: opt-in\n");
    } else {
      if (lib.opt_out) lib.opt_out();
      LogToFile(L"[BrightSDK] handleConsentChange: opt-out\n");
    }
  }

  // Matches Android: BrightSdkNativeModule.reportConsentShown()
  REACT_METHOD(reportConsentShown, L"reportConsentShown")
  void reportConsentShown() noexcept {
    LogToFile(L"[BrightSDK] reportConsentShown\n");
  }

  REACT_METHOD(getConsentChoice, L"getConsentChoice")
  void getConsentChoice(
      winrt::Microsoft::ReactNative::ReactPromise<winrt::Microsoft::ReactNative::JSValue> promise) noexcept {
    auto &lib = GetBrightSdkLib();
    if (!lib.loaded() || !lib.get_consent_choice) {
      promise.Resolve(winrt::Microsoft::ReactNative::JSValue::Null);
      return;
    }
    int choice = lib.get_consent_choice();
    switch (choice) {
      case LUM_SDK_CHOICE_PEER:
        promise.Resolve(winrt::Microsoft::ReactNative::JSValue(true));
        break;
      case LUM_SDK_CHOICE_NOT_PEER:
        promise.Resolve(winrt::Microsoft::ReactNative::JSValue(false));
        break;
      default:
        promise.Resolve(winrt::Microsoft::ReactNative::JSValue::Null);
        break;
    }
  }

  REACT_METHOD(fixServiceStatus, L"fixServiceStatus")
  void fixServiceStatus() noexcept {
    auto &lib = GetBrightSdkLib();
    if (lib.loaded() && lib.fix_service_status)
      lib.fix_service_status();
  }

  REACT_METHOD(closeSdk, L"closeSdk")
  void closeSdk() noexcept {
    auto &lib = GetBrightSdkLib();
    if (lib.loaded() && lib.close) {
      lib.close();
      LogToFile(L"[BrightSDK] closeSdk: closed\n");
    }
  }

  REACT_METHOD(getUuid, L"getUuid")
  void getUuid(
      winrt::Microsoft::ReactNative::ReactPromise<winrt::Microsoft::ReactNative::JSValue> promise) noexcept {
    auto &lib = GetBrightSdkLib();
    if (lib.loaded() && lib.get_uuid) {
      const char *sdkUuid = lib.get_uuid();
      if (sdkUuid && sdkUuid[0] != '\0') {
        promise.Resolve(winrt::Microsoft::ReactNative::JSValue(sdkUuid));
        return;
      }
    }
    promise.Resolve(winrt::Microsoft::ReactNative::JSValue::Null);
  }

private:
  static void WINAPI OnChoiceChanged(int choice) {
    LogToFile((L"[BrightSDK] OnChoiceChanged: " + std::to_wstring(choice) + L"\n").c_str());
    if (!s_instance || !s_instance->m_context) return;
    bool isPeer = (choice == LUM_SDK_CHOICE_PEER);
    s_instance->m_context.EmitJSEvent(
        L"RCTDeviceEventEmitter", L"onBrightSdkChoiceChanged",
        winrt::Microsoft::ReactNative::JSValueObject{
            {"choice", choice},
            {"isPeer", isPeer}});
  }

  winrt::Microsoft::ReactNative::ReactContext m_context{nullptr};
  static inline BrightSdkNativeModule *s_instance = nullptr;
};

} // namespace BrightSdk
