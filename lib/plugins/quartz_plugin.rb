require 'open4'
require 'json'

class QuartzPlugin
	
	def initialize(log, options)
		@log = log
		@options = options
	end	

	def run_result(success, message)
		result = { :ok => success, :message => message }
		@log.debug "Job finished with result #{result}"

		result
	end

	def payload(message)
		v = message['payload']
		@log.debug "Payload received: #{v}"
		v = v.merge({'job_name' => message['job_name']})
		@log.debug "Payload used: #{v}"
		v
	end

	def run_shell(command)
		pid, stdin, stdout, stderr = Open4::popen4("#{command}")
		ignored, status = Process::waitpid2 pid

		if status.exitstatus == 0
			{ :ok => true, :message => stdout.read.strip }
		else
			{ :ok => false, :message => stderr.read.strip}
		end
	end

	@@version_major = 0
	@@version_minor = 0
	@@version_revision = 1

	def get_version
		"#{@@version_major}.#{@@version_minor}.#{@@version_revision}"
	end
end