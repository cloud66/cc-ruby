require 'rake'
require 'yaml'
require 'logger'

@log = Logger.new(STDOUT)

desc "Runs a plugin with payload from a YAML file"
task :run, :plugin do |t, args|
	begin
		plugin = args[:plugin]

		require File.expand_path("../../lib/plugins/#{plugin}", __FILE__)

		@log.debug "Loading payload for #{plugin} from payloads/#{args[:plugin]}_payload.yml"
		payload = YAML::load(File.open("payloads/#{plugin}_payload.yml"))
	
		classname = plugin.split('_').collect{ |part| part.capitalize }.join
		clazz = Kernel.const_get(classname)
		instance = clazz.new(@log, { :api_key => "", :agent_id => "" })
		@log.debug "Test class loaded: #{classname}"

		message = payload
		message = { 'payload' => payload, 'job_name' => 'Test Runner'}
		instance.run(message)
	rescue => exc
		@log.error "Run failed due to #{exc}"
		backtrace = exc.backtrace.join("\n")
		@log.error "STACK: #{backtrace}"
	end
end
