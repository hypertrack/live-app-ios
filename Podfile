source 'https://cdn.cocoapods.org/'

platform :ios, '13.0'

inhibit_all_warnings!

def live_app_pods
  pod 'AWSMobileClient'
  pod 'HyperTrack', '5.0.2'
  pod 'HyperTrackViews/MapKit', '0.6.0'
  pod 'lottie-ios', '3.1.9'
  pod 'Branch', '1.39.2'
end

target 'LiveApp' do
  use_frameworks!
  live_app_pods
end

target 'Prelude' do
  use_frameworks!
  live_app_pods
end

target 'Model' do
  use_frameworks!
  live_app_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
      deployment_target = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      if !deployment_target.nil? && !deployment_target.empty? && deployment_target.to_f < 12.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
  end
end
