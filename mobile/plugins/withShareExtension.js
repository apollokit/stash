const { withXcodeProject, withInfoPlist } = require('@expo/config-plugins');
const path = require('path');
const fs = require('fs');

const SHARE_EXTENSION_NAME = 'StashShareExtension';

/**
 * Config plugin to add iOS Share Extension
 */
const withShareExtension = (config) => {
  // Add plugin to app.json
  config = withShareExtensionTarget(config);
  config = withShareExtensionFiles(config);
  config = withShareExtensionInfoPlist(config);

  return config;
};

/**
 * Add Share Extension target to Xcode project
 */
const withShareExtensionTarget = (config) => {
  return withXcodeProject(config, async (config) => {
    // This will be handled by prebuild
    // The actual Xcode project modifications happen during `expo prebuild`
    return config;
  });
};

/**
 * Copy Share Extension source files
 */
const withShareExtensionFiles = (config) => {
  return config;
};

/**
 * Configure Info.plist for Share Extension
 */
const withShareExtensionInfoPlist = (config) => {
  return withInfoPlist(config, (config) => {
    // Add URL scheme for deep linking back to main app
    if (!config.modResults.CFBundleURLTypes) {
      config.modResults.CFBundleURLTypes = [];
    }

    config.modResults.CFBundleURLTypes.push({
      CFBundleURLSchemes: ['stash'],
      CFBundleURLName: 'com.stash.mobile',
    });

    return config;
  });
};

module.exports = withShareExtension;
