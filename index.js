import { NativeModules, DeviceEventEmitter } from 'react-native';

const sdk = NativeModules.BrightSdkNativeModule || {};

export default {
  init: () => sdk.initBrightSdk?.(),
  setAppId: (appId) => sdk.setAppId?.(appId),
  reportConsentShown: () => sdk.reportConsentShown?.(),
  enable: () => sdk.handleConsentChange?.(true),
  disable: () => sdk.handleConsentChange?.(false),
  getConsentChoice: () => sdk.getConsentChoice?.() ?? Promise.resolve(null),
  getUuid: () => sdk.getUuid?.() ?? Promise.resolve(null),
  close: () => sdk.closeSdk?.(),
  fixServiceStatus: () => sdk.fixServiceStatus?.(),
  onChoiceChanged: (callback) =>
    DeviceEventEmitter.addListener('onBrightSdkChoiceChanged', callback),
};
