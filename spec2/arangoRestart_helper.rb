require "rspec"
require_relative File.expand_path('../../lib/arangorb', __FILE__)

RSpec.configure do |config|
	config.color = true
end

describe ArangoServer do
	context "#restart" do
		it "restart" do
			print ArangoServer.restart
		end
	end
end
