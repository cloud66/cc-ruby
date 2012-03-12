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

end