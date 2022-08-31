# Azure Npm Patch Script

## Purpose
The script when run like the example below patches the `package.json` version number in the build if the `major.minor` version already exists in azure artifacts.

If the artifact does not exist, patching is ignored and the version in `package.json` is kept.

## Usage
```
steps:
...
  - task: ShellScript@2
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    displayName: Update version patch if needed
    env:
      ORGANISATION_NAME: 'helseapps'
      PROJECT_NAME: 'Helseboka'
      FEED_NAME: 'VigorKit'
      SYSTEM_ACCESS_TOKEN: $(System.AccessToken)
    inputs:
      scriptPath: ./bump_patch_version.sh
...
```

