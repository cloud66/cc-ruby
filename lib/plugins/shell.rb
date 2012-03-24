require File.join(File.dirname(__FILE__), 'quartz_plugin')

class Shell < QuartzPlugin
	def info
		{ :uid => "20e07c656e2f477d969e9561e13229fb", :name => "Shell", :version => "0.0.0" }
	end

	def run(message)
		@log.debug "Running with #{message}"
		payload = payload(message)
		command = payload['command']
		params = payload['params']
		@log.info "Shell command '#{command}' with '#{params}'"

		begin
			result = run_shell("#{command} #{params}")
			run_result(result[:ok], result[:message])
		rescue => ex
			run_result(false, "Failed to run shell command due to #{ex}")
		end
	end
end	