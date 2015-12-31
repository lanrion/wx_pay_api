$:.push File.expand_path("../lib", __FILE__)

require "wx_pay/version"

Gem::Specification.new do |s|
  s.name          = "wx_pay_api"
  s.version       = WxPay::VERSION
  s.authors       = ["Jasl", "lanrion"]
  s.email         = ["jasl9187@hotmail.com", "huaitao-deng@foxmail.com"]
  s.homepage      = "https://github.com/lanrion/wx_pay_api"
  s.summary       = "An unofficial simple wechat pay gem"
  s.description   = "An unofficial simple wechat pay gem"
  s.license       = "MIT"

  s.require_paths = ["lib"]

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  s.add_runtime_dependency "rest-client", '>= 1.7'
  s.add_runtime_dependency "activesupport", '>= 3.2'

  s.add_development_dependency "bundler", '~> 1'
  s.add_development_dependency "rake", '~> 10'

  s.add_development_dependency "rspec"
  s.add_development_dependency 'pry-rails'

end
