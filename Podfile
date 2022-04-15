source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '12.0'
use_frameworks!
inhibit_all_warnings!

target :'RxPagination' do
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'Action'
  pod 'RxSwiftExt'
  pod 'RxOptional'
end

target :'RxPaginationTests' do
  pod 'Quick'
  pod 'Nimble'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxTest'
end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
