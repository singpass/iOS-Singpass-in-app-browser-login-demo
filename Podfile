platform :ios, '12.0'

target 'sample' do
  use_frameworks!
  pod 'AppAuth'

end

post_install do |installer|
		installer.generated_projects.each do |project|
			project.targets.each do |target|
				target.build_configurations.each do |config|
					config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
				end
			end
	 end
end
