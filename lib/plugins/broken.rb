require File.join(File.dirname(__FILE__), 'quartz_plugin')

class Broken < QuartzPlugin

	@@version_major = 0
	@@version_minor = 0
	@@version_revision = 1
	
	def info
		{ :uid => "04165a45fde840a9a17b41f019b3dca3", :name => "Broken", :version => get_version }
	end

	def run(message)
		@log.info "Running with #{message}"
		@log.info "This is a failure"

		run_result(false, "Boo! It's broken")
	end
end	