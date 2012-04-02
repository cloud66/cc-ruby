require File.join(File.dirname(__FILE__), 'quartz_plugin')
require 'fileutils'
require 'fog'

class S3backup < QuartzPlugin

	def info
		{ :uid => "d3533989f9d542f393566511e8eb2090", :name => "S3 Backup", :version => "0.0.0" }
	end

	def run(message)
		pl = payload(message)

		@log.debug "Pruned payload #{pl}"

		@access_key_id 			= pl['access key']
		@secret_access_key 		= pl['secret key']
		@bucket 				= pl['bucket']
		@remote_path 			= pl['remote path']
		@region 				= pl['region']
		@local_pattern 			= pl['local pattern']
		@keep 					= pl['keep'].empty? ? 0 : pl['keep'].to_i

		@testing				= pl['testing']

		return transfer
	end

	private

	def connection
		Fog.mock! unless @testing.nil? || @testing == false
		@connection ||= Fog::Storage.new(
			:provider               => 'AWS',
			:aws_access_key_id      => @access_key_id,
			:aws_secret_access_key  => @secret_access_key,
			:region                 => @region
		)
	end

	def remote_path_for(filename)
		filename.sub(/^\//, '')
	end

	def transfer
		begin
			remote_path = remote_path_for(@remote_path)
			@log.debug "Remote path is #{remote_path}"

			@log.debug "Syncronizing local and remote clocks"
			connection.sync_clock

			count = 0
			# get local files
			directory = connection.directories.get(@bucket)
			all_rotated = directory.files.reject { |m| File.dirname(m.key) != @remote_path }

			Dir.glob(@local_pattern).each do |f|
				base_file = File.basename(f)
				remote_files = all_rotated.map {|m| File.basename(m.key)}
				unless remote_files.include? base_file
					remote_file = File.join(@remote_path, base_file)
					next if File.directory?(f)
					@log.debug "Copying #{f} to #{remote_file}"
					count += 1
					File.open(f, 'r') do |file|
						connection.put_object(@bucket, File.join(remote_path, base_file), file)
					end
				end
			end

			return run_result(true, "Files copied to S3 bucket successfully with no rotation") if @keep == 0

			@log.debug "Found #{all_rotated.count} in the remote bucket"
			if all_rotated.count > @keep
				remove_count = all_rotated.count - @keep
				@log.debug "Removing #{remove_count} and keeping the most recent #{@keep}"
				to_remove = all_rotated.sort { |a,b| a.last_modified <=> b.last_modified }.map{|m| m.key }[0...remove_count]
				@log.debug "Removing extra files"
				to_remove.each do |tr|
					@log.debug "Removing #{tr}"
					connection.delete_object(@bucket, tr)
				end
			end
		rescue Excon::Errors::SocketError => exc
			@log.error exc.message
			return run_result(false, exc.message)
		rescue Excon::Errors::Error => exc
			@log.error exc.message
			result = exc.response.body
			message = result.match(/\<Message\>(.*)\<\/Message\>/)
			if !message.nil?
				message = message[1] 
				return run_result(false, message)
			elsif exc.response.status == 404
				return run_result(false, "Remote S3 serivce or bucket not found (404)")
			elsif exc.response.status != 0
				return run_result(false, "Remote S3 serivce returned error #{exc.response.status} without any more details")
			else
				return run_result(false, exc.message)
			end
		end

		run_result(true, "Successfully copied #{count} files to S3")
	end
end	