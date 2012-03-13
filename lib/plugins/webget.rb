require File.join(File.dirname(__FILE__), 'quartz_plugin')
require 'HTTParty'

class Webget < QuartzPlugin
	def info
		{ :uid => "6b5f722d214f4d71a5be237d44094721", :name => "WebGet", :version => "0.0.0" }
	end

	def run(message)
		@log.debug "Running with #{message}"
		payload = payload(message)
		url = payload['url']
		local = payload['local file']
		@log.info "Webget from #{url} into #{local}"

		begin
			response = HTTParty.get(url)
			if response.code == 200
				body = response.body
				file = File.new(local, "w")
				begin
					file.write(body)
					run_result(true, "Saved WebGet to local file")
				ensure
					file.close
				end
			else
				run_result(false, response.message)
			end
		rescue => ex
			run_result(false, "Failed to webget due to #{ex}")
		end
	end
end	