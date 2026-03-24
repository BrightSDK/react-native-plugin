#include "pch.h"
#include "ReactPackageProvider.h"
#if __has_include("ReactPackageProvider.g.cpp")
#include "ReactPackageProvider.g.cpp"
#endif

#include "BrightSdkNativeModule.h"

using namespace winrt::Microsoft::ReactNative;

namespace winrt::BrightSdkModule::implementation {

void ReactPackageProvider::CreatePackage(IReactPackageBuilder const &packageBuilder) noexcept {
  BrightSdk::LogToFile(L"[BrightSDK] CreatePackage called\n");
  AddAttributedModules(packageBuilder, true);
  BrightSdk::LogToFile(L"[BrightSDK] CreatePackage done\n");
}

} // namespace winrt::BrightSdkModule::implementation
