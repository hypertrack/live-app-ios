<a href="https://hypertrack.com/">
    <img src="https://www.hypertrack.com/images/logo.svg" alt="Hypertrack logo" title="Hypertrack" align="right" height="60" />
</a>

Hypertrack Live iOS 
===================

[![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://opensource.org/licenses/MIT) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Through hypertrack live you can share your live location with friends through your favorite messaging app when on the way to meet up. You can also see your activities organized as chronological cards so that tapping on each card gives you the locations of the activity.

![Live Location Sharing](assets/placeline.gif) ![Placeline](assets/placeline.gif)

- [How to use](how-to-use)
- [Building Blocks](building-blocks)
- [Build Live Location features](build-live-location-features)


## How to use

```bash
# Clone this repository
$ git clone https://github.com/hypertrack/hypertrack-live-ios.git

# Go into the repository
$ cd hypertrack-live-ios

# Install dependencies
$ pod install
```

Get your HyperTrack API keys [here](https://dashboard.hypertrack.com/signup), and add the publishable key to setUpHypertrack function in [HyperTrackAppService.swift](https://github.com/hypertrack/hypertrack-live-ios/blob/master/htlive-ios/htlive-ios/HyperTrackAppService.swift) file.
```swift
        HyperTrack.initialize("YOUR_PUBLISHABLE_KEY")
```

## Building Blocks



## Build Live Location Features using HyperTrack

- [Setup](#setup)
  - [Get API Keys](#get-api-keys)
  - [Setup HyperTrack SDK](#setup-hypertrack-sdk)
- [Create a HyperTrack User](#create-a-hypertrack-user)
- [Show Live Location View](#show-live-location-view)

  
### Setup 
#### Get API Keys
Get your HyperTrack API keys [here](https://dashboard.hypertrack.com/signup)
#### Setup HyperTrack SDK
Set up HyperTrack by following the instructions from [here](https://docs.hypertrack.com/sdks/ios/setup.html). If you prefer watching a video, you’re in luck. Watch the short video [here]() 

### Create a HyperTrack User
### Show Live Location View
### Create and Track Action
### Share the trip's lookup id
### Track Action 
### Join the trip






