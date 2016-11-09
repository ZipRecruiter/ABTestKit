Pod::Spec.new do |s|
  s.name             = 'ABTestKit'
  s.version          = '1.0'
  s.summary          = 'AB Tests framework in Swift  3.'
  s.description      = <<-DESC
Use ABTestKit to randomly bukcet users, and run code based on these buckets quickly and easily with closures.
This framework supports Obj-C but is designed with Swift in mind.
                       DESC

  s.homepage         = 'https://github.com/ZipRecruiter/ABTestKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Yariv Nissim' => 'yariv@ziprecruiter.com' }
  s.source           = { :git => 'https://github.com/ZipRecruiter/ABTestKit.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/yar1vn'

  s.ios.deployment_target = '9.0'

  s.source_files = 'ABTestKit/Classes/**/*'
  
  # s.resource_bundles = {
  #   'ABTestKit' => ['ABTestKit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
