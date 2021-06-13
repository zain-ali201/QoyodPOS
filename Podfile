# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'Qoyod point of sale' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  
  # ignore all warnings from all pods
  inhibit_all_warnings!

  # Pods for Qoyod point of sale

  pod 'ReachabilitySwift'
  pod 'JVFloatLabeledTextField'
  pod 'NVActivityIndicatorView'
  pod 'CocoaBar'
  pod 'ActionButton', :git => 'https://github.com/matsoft90/ActionButton', :branch => 'swift-4-plus-additions'
  pod 'BarcodeScanner'
  pod 'DLRadioButton', '~> 1.4'
  pod 'Bugsnag'
  pod 'Toast-Swift'
  pod 'CollapsibleTableSectionViewController'
  pod 'CCBottomRefreshControl'

  target 'Qoyod point of saleTests' do
    inherit! :search_paths
    # Pods for testing
  end
  
  post_install do |installer|
      installer.pods_project.build_configurations.each do |config|
          config.build_settings.delete('CODE_SIGNING_ALLOWED')
          config.build_settings.delete('CODE_SIGNING_REQUIRED')
      end
  end

end
