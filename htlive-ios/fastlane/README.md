fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

## Choose your installation method:

| Method                     | OS support                              | Description                                                                                                                           |
|----------------------------|-----------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| [Homebrew](http://brew.sh) | macOS                                   | `brew cask install fastlane`                                                                                                          |
| Installer Script           | macOS                                   | [Download the zip file](https://download.fastlane.tools). Then double click on the `install` script (or run it in a terminal window). |
| RubyGems                   | macOS or Linux with Ruby 2.0.0 or above | `sudo gem install fastlane -NV`                                                                                                       |

# Available Actions
## iOS
### ios xcode
```
fastlane ios xcode
```
Installs FixCode which disables the "Fix Issue" button in Xcode
### ios test
```
fastlane ios test
```
Runs all the unit and ui tests
### ios screens
```
fastlane ios screens
```
Creates new screenshots and uploads them to iTunes Connect
### ios beta
```
fastlane ios beta
```
Submits a new Beta Build to Apple TestFlight
### ios deploy
```
fastlane ios deploy
```
Deploys a new version to the App Store

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
