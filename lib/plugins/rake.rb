require File.join(File.dirname(__FILE__), 'quartz_plugin')

class Rake < QuartzPlugin
	def info
		{ :uid => "62e3583abfc24f209916c4ff97661fa0", :name => "Rake", :version => "0.0.0" }
	end

	def run(message)
		@log.debug "Running with #{message}"
		payload = payload(message)
		task = payload['task']
		location = payload['location']
		params = payload['params']
		@log.info "Rake #{task} in #{location} with params:#{params}"

		begin
			return run_shell("bundle", "exec rake #{task} #{params}")
		rescue => ex
			run_result(false, "Failed to run rake due to #{ex}")
		end
	end
end	