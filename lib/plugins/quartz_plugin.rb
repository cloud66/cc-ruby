require 'open4'

class QuartzPlugin
	
	def initialize(log, options)
		@log = log
		@options = options
	end	


	def run_result(success, message)
		{ :ok => success, :message => message }
	end

	def payload(message)
		raw_payload = message['payload']
		parsed_payload = JSON.parse(raw_payload) unless raw_payload.nil?

		v = {}
		unless parsed_payload.nil?
			parsed_payload.each do |p|
				v = v.merge({ p['name'] => p['value']})
			end
		end

		@log.debug "Payload #{v}"

		v
	end

	def run_shell(command, params)
		pid, stdin, stdout, stderr = Open4::popen4("#{command} #{params}")
		ignored, status = Process::waitpid2 pid

		if status.exitstatus == 0
			run_result(true, stdout.read.strip)
		else
			run_result(false, stderr.read.strip)
		end
	end
end