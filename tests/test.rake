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
		@log.debug "Loaded #{payload}"

		@log.debug "Loading #{plugin} class"
		clazz = Kernel.const_get(plugin.capitalize)
		instance = clazz.new(@log, { :api_key => "", :agent_id => "" })

		message = []
		payload.each do |k, v|
			message << { :name => k.gsub(/_/, ' '), :value => v }
		end
		@log.debug "Message #{message}"
		message = { 'payload' => message.to_json, 'job_name' => 'Test Runner'}
		instance.run(message)
	rescue => exc
		@log.error "Run failed due to #{exc}"
	end
end
