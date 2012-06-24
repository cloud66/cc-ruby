require File.join(File.dirname(__FILE__), 'quartz_plugin')

class Rake < QuartzPlugin

	@@version_major = 0
	@@version_minor = 0
	@@version_revision = 1

	def info
		{ :uid => "62e3583abfc24f209916c4ff97661fa0", :name => "Rake", :version => get_version }
	end

	def run(message)
		@log.debug "Running with #{message}"
		payload = payload(message)
		task = payload['task']
		location = payload['location']
		params = payload['params']
		@log.info "Rake #{task} in #{location} with params:#{params}"

		begin
			result = run_shell("bundle exec rake #{task} #{params}")
			run_result(result[:ok], result[:message])
		rescue => ex
			run_result(false, "Failed to run rake due to #{ex}")
		end
	end
end	