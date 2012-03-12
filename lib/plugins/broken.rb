require File.join(File.dirname(__FILE__), 'quartz_plugin')

class Broken < QuartzPlugin
	def guid
		"04165a45fde840a9a17b41f019b3dca3"
	end

	def run(message)
		@log.info "Running with #{message}"
		@log.info "This is a failure"

		{ :ok => false, :message => "Boo! It's broken" }
	end
end	