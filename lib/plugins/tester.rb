require File.join(File.dirname(__FILE__), 'quartz_plugin')

class Tester < QuartzPlugin
	def guid
		"c0bb6ed7950b489f9abba8071ff0e0ab"
	end

	def run(message)
		@log.info "Running with #{message}"
		i = Random.rand(10)
		@log.info "Waiting for #{i} seconds"
		sleep i
		@log.info "Done"

		{ :ok => true, :message => "Super! Done in #{i} seconds" }
	end
end