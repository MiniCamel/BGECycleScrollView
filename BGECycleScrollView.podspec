Pod::Spec.new do |s|
    s.name             = 'BGECycleScrollView'
    s.version          = '1.0.0'
    s.summary          = 'Swift循环滚动视图控件'
    s.description      = <<-DESC
        Swift循环滚动视图控件
    DESC
    s.homepage         = 'https://github.com/MiniCamel/BGECycleScrollView'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Bge' => 'tiandiwuji1223@163.com' }
    s.source           = { :git => 'https://github.com/MiniCamel/BGECycleScrollView.git', :tag => s.version.to_s }
    s.platform = :ios, '9.0'
    s.ios.deployment_target = '9.0'
    s.source_files = 'BGECycleScrollView/Classes/**/*'
    s.dependency 'Masonry'
    s.requires_arc = true
end
