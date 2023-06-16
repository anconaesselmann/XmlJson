Pod::Spec.new do |s|
  s.name             = 'XmlJson'
  s.version          = '1.0.2'
  s.summary          = 'XmlJson is a simple declarative library for reading and writing XML'

  s.description      = <<-DESC
XmlJson is a simple declarative library for reading and writing XML.
                       DESC

  s.homepage         = 'https://github.com/anconaesselmann/XmlJson'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'anconaesselmann' => 'axel@anconaesselmann.com' }
  s.source           = { :git => 'https://github.com/anconaesselmann/XmlJson.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.source_files = 'Sources/XmlJson/**/*'
end