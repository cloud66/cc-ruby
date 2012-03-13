require File.join(File.dirname(__FILE__), 'quartz_plugin')

class Tester < QuartzPlugin
	def info
		{ :uid => "c0bb6ed7950b489f9abba8071ff0e0ab", :name => "Tester", :version => "0.0.0" }
	end

	def run(message)
		@log.info "Running with #{message}"
		i = Random.rand(10)
		@log.info "Waiting for #{i} seconds"
		sleep i
		@log.info "Done"

		run_result(true, "Super! Done in #{i} seconds")
	end
end	