require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'TrinitiwowkaCapacitorTrueTime'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url']
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => s.version.to_s }
  s.source_files = 'ios/Sources/**/*.{swift,h,m,c,cc,mm,cpp}', 'ios/Vendor/TrueTime/Sources/**/*.{swift,h}'
  s.public_header_files = 'ios/Vendor/TrueTime/Sources/CTrueTime/*.h'
  s.preserve_paths = 'ios/Vendor/TrueTime/Sources/CTrueTime/module.modulemap'
  s.pod_target_xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/ios/Vendor/TrueTime/Sources/CTrueTime' }
  s.ios.deployment_target = '15.0'
  s.dependency 'Capacitor'
  s.frameworks = 'Network', 'SystemConfiguration'
  s.swift_version = '5.9'
end
