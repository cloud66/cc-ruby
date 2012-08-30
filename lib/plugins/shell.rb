require File.join(File.dirname(__FILE__), 'quartz_plugin')

class Shell < QuartzPlugin
	
	@@version_major = 0
	@@version_minor = 0
	@@version_revision = 1

	def info
		{ :uid => "20e07c656e2f477d969e9561e13229fb", :name => "Shell", :version => get_version }
	end

	def run(message)
		@log.debug "Running with #{message}"
		payload = payload(message)
		command = payload['command']
		@log.info "Shell command '#{command}'"

		begin
			result = run_shell("#{command}")
			run_result(result[:ok], result[:message])
		rescue => ex
			run_result(false, "Failed to run shell command due to #{ex}")
		end
	end
end	