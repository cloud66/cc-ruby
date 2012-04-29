require File.join(File.dirname(__FILE__), 'quartz_plugin')
require 'fileutils'

class Mysql < QuartzPlugin

	def info
		{ :uid => "67deb35a555344c8a7651c656e6c8e2e", :name => "MySQL Backup", :version => "0.0.0" }
	end

	def run(message)
		pl = payload(message)
		pl = pl.select { |k,v| !v.nil? && !v.empty? }

		@log.debug "Pruned payload #{pl}"

		@job_name 			= pl['job_name'].gsub(/[^\w\s_-]+/, '').gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2').gsub(/\s/, '_')
		@mysqldump_utility 	= pl['dump_utility'] || '/usr/bin/mysqldump'
		@name 				= pl['db_name'] || :all
		@username 			= pl['username']
		@password 			= pl['password']
		@socket 			= pl['socket']
		@host 				= pl['host']
		@port 				= pl['port']
		@skip_tables 		= pl['skip_tables']
		@only_tables 		= pl['only_tables']
		@additional_options = pl['additional_options'] || ['--single-transaction', '--quick']
		@path 				= pl['backup_folder']

		@only_tables = @only_tables.split(',') unless @only_tables.nil?
		@skip_tables = @skip_tables.split(',') unless @skip_tables.nil?

        dump_cmd = "#{mysqldump} | gzip > '#{ File.join(@path, @job_name.downcase) }.sql.gz'"
        @log.debug "Running #{dump_cmd}"
        
        FileUtils.mkdir_p(@path)

		result = run_shell dump_cmd
		if result[:ok]
			run_result(true, "MySQL Backup finished successfully")
		else
			run_result(false, result[:message])
		end
	end

	private 

	# copied from backup gem with little mods
	def mysqldump
		"#{ @mysqldump_utility } #{ credential_options } #{ connectivity_options } " +
		"#{ user_options } #{ @name } #{ tables_to_dump } #{ tables_to_skip }"
	end

	def credential_options
		%w[username password].map do |option|
			value = instance_variable_get("@#{option}")
			next if value.to_s.empty?
			"--#{option}='#{value}'".gsub('--username', '--user')
		end.compact.join(' ')
	end

	def connectivity_options
		%w[host port socket].map do |option|
			value = instance_variable_get("@#{option}")
			next if value.to_s.empty?
			"--#{option}='#{value}'"
		end.compact.join(' ')
	end

	def user_options
		@additional_options.join(' ') unless @additional_options.nil?
	end

	def tables_to_dump
		@only_tables.join(' ') unless @only_tables.nil? || dump_all?
	end

	def tables_to_skip
		return '' if @skip_tables.nil?
		@skip_tables.map do |table|
			"--ignore-table='#{@name}.#{table}'"
		end.join(' ') unless dump_all?
	end

	def dump_all?
		@name == :all
	end

end	