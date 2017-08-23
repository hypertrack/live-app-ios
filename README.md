<a href="https://hypertrack.com/">
    <img src="https://www.hypertrack.com/images/logo.svg" alt="Hypertrack logo" title="Hypertrack" align="right" height="60" />
</a>

Hypertrack Live 
===============

[![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://opensource.org/licenses/MIT) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Through hypertrack live you can share your live location with friends through your favorite messaging app when on the way to meet up. You can also see your activities organized as chronological cards so that tapping on each card gives you the locations of the activity.

![Live Location Sharing](assets/placeline.gif) ![Placeline](assets/placeline.gif)

- [How to use](how-to-use)
- [Build Live Location features](build-live-location-features)
- [Building Blocks](building-blocks)



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




## Build Live Location Sharing using HyperTrack in 30 Minutes

- [Setup](#setup)
  - [Get API Keys](#step-1-get-api-keys)
  - [Use Starter Project](#step-2-use-starter-project)
  - [Setup HyperTrack SDK](#step-3-setup-hypertrack-sdk)
- [Create a HyperTrack User](#step-4-create-a-hypertrack-user)
- [Show Live Location View](#show-live-location-view)

  
### Setup 

#### Step 1. Get API Keys
Get your HyperTrack API keys [here](https://dashboard.hypertrack.com/signup)
#### Step 2. Use Starter Project
We have created a starter project so that building Live Location Sharing becomes very easy and quick. It will prevent you from the hassle of creating a new project and the workflow to enable live location sharing. If you want to directly build the flow in your own app or wanted to create a new project, you can ignore this step.

```bash
# Clone this repository
$ git clone https://github.com/hypertrack/hypertrack-live-ios.git

# Go into the starter folder in the repository
$ cd hypertrack-live-ios/starter/

# Install dependencies
$ pod install
```

#### Step 3. Setup HyperTrack SDK
If you are not using the starter project set up HyperTrack by following the instructions from [here](https://docs.hypertrack.com/sdks/ios/setup.html). Otherwise initialize the SDK by putting the following code :  
```swift
// AppDelegate.swift
        HyperTrack.initialize("pk_e956d4c123e8b726c10b553fe62bbaa9c1ac9451")
        HyperTrack.requestLocationServices()
```
in AppDelegate in the following function like : 

```swift
 func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Step 3: initialize hypertrack sdk and request for permissions here
        HyperTrack.initialize("pk_e956d4c123e8b726c10b553fe62bbaa9c1ac9451")
        HyperTrack.requestLocationServices()
        return true
    }

```

#### Step 4. Create a HyperTrack User
The next logical thing that you need to do is create a Hypertrack User. It helps Hypertrack to tag the location/activity data of a user and in turn help us to share status of your live location to your friends. More details about the function is present here(https://docs.hypertrack.com/sdks/ios/basic.html#step-1-create-sdk-user). 

For starter project - UserProfileViewController.swift. When the user press login, take the name of the user and use the below function to create a user.

```swift
    HyperTrack.getOrCreateUser("USER_NAME", "PHONE", "LOOK_UP_ID") { (user, error) in
            
            if (error != nil) {
                // Handle error on get or create user
                return
            }
            
            if (user != nil) {
                // User successfully created
                print("User created:", user!.id ?? "")
                HyperTrack.startTracking()
            }
        }
```
### Show Live Location View
### Create and Track Action
### Share the trip's lookup id
### Track Action 
### Join the trip


## Building Blocks





