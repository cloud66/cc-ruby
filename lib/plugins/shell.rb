require File.join(File.dirname(__FILE__), 'quartz_plugin')
require 'open4'

class Shell < QuartzPlugin
	def guid
		"20e07c656e2f477d969e9561e13229fb"
	end

	def name
		"Shell"
	end

	def version
		"0.0.0"
	end

	def run(message)
		@log.debug "Running with #{message}"
		payload = payload(message)
		command = payload['command']
		params = payload['params']
		@log.info "Shell command '#{command}' with '#{params}'"

		begin
			pid, stdin, stdout, stderr = Open4::popen4("#{command} #{params}")
			ignored, status = Process::waitpid2 pid

			if status.exitstatus == 0
				run_result(true, stdout.read.strip)
			else
				run_result(false, stderr.read.strip)
			end
			
		rescue => ex
			run_result(false, "Failed to run shell command due to #{ex}")
		end
	end
end	