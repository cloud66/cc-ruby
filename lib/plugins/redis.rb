require File.join(File.dirname(__FILE__), 'quartz_plugin')
require 'fileutils'

class Redis < QuartzPlugin

	def info
		{ :uid => "6342c1ef0d8bb2a47ab1362a6b02c058", :name => "Redis Backup", :version => "0.0.0" }
	end

	def run(message)
		pl = payload(message)

		@job_name 			= pl['job_name'].gsub(/[^\w\s_-]+/, '').gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2').gsub(/\s/, '_')
		@redisdump_utility 	= pl['redis_client'] || '/usr/bin/redis-cli'
		@name 				= pl['db_name'] || 'dump'
		@password 			= pl['password']
		@socket 			= pl['socket']
		@host 				= pl['host'] || '127.0.0.1'
		@port 				= pl['port'] || 6379
		@additional_options = pl['additional_options'] || []
		@path 				= pl['db_path']
		@dump_path			= pl['backup_folder']

		@name = 'dump' if @name.empty?
		@host = '127.0.0.1' if @host.empty?
		@port = 6379 if @port.empty?
		@additional_options = [] if @additional_options.empty?
		@redisdump_utility = '/usr/bin/redis-cli' if @redisdump_utility.empty?

		save_result = invoke_save
		return save_result unless save_result.nil?

		result = copy
		if result[:ok]
			run_result(true, "Redis Backup finished successfully")
		else
			run_result(false, result[:message])
		end
	end

	private 

	## based on Backup Gem with minor modifications

	def database
		"#{@name}.rdb"
	end

	def credential_options
		@password.to_s.empty? ? '' : "-a '#{@password}'"
	end

	def connectivity_options
		%w[host port socket].map do |option|
			value = instance_variable_get("@#{option}")
			next if value.to_s.empty?
			"-#{option[0,1]} '#{value}'"
		end.compact.join(' ')
	end

	def user_options
		@additional_options.join(' ')
	end

	def invoke_save
		command = "#{@redisdump_utility} #{credential_options} #{connectivity_options} #{user_options} SAVE"
		@log.debug "Running #{command}"
		response = run_shell(command)
		@log.debug "redis-cli run result: #{response}"
		unless response[:ok]
			run_result(false, "Failed to save from server '#{response[:message]}'")
		else
			nil
		end
    end

	def copy
		src_path = File.join(@path, database)
		unless File.exist?(src_path)
			raise "Redis database dump not found at #{src_path}"
		end

		FileUtils.mkdir_p(@dump_path)

		dst_path = File.join(@dump_path, database)
		dump_cmd = "gzip -c #{src_path} > #{dst_path}.gz"
		@log.debug "Running #{dump_cmd}"
		run_shell dump_cmd
	end

end	