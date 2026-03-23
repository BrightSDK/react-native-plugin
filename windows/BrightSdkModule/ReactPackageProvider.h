#pragma once

#include "NativeModules.h"

using namespace winrt::Microsoft::ReactNative;

namespace winrt::BrightSdkModule::implementation {

struct ReactPackageProvider : winrt::implements<ReactPackageProvider, IReactPackageProvider> {
  void CreatePackage(IReactPackageBuilder const &packageBuilder) noexcept {
    AddAttributedModules(packageBuilder, true);
  }
};

} // namespace winrt::BrightSdkModule::implementation
