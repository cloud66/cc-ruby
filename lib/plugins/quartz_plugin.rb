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
		@log.debug "Message #{message}"
		raw_payload = message['payload']
		@log.debug "Payload #{raw_payload}"
		parsed_payload = JSON.parse(raw_payload) unless raw_payload.nil?
		@log.debug "Parsed payload #{parsed_payload}"

		v = parsed_payload
		v = v.merge({'job_name' => message['job_name']})

		@log.debug "Payload #{v}"

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
end