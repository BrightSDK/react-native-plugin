module.exports = {
  dependency: {
    platforms: {
      windows: {
        sourceDir: 'windows',
        projects: [
          {
            projectFile: 'BrightSdkModule/BrightSdkModule.vcxproj',
            directDependency: true,
          },
        ],
      },
    },
  },
};
