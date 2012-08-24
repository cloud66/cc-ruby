require File.join(File.dirname(__FILE__), 'quartz_plugin')
require 'fileutils'
require 'fog'
require 'set'

class RackspaceBackup < QuartzPlugin

	@@version_major = 0
	@@version_minor = 0
	@@version_revision = 1

	def info
		{ :uid => "86a34908c51311e1a0a923db6188709b", :name => "Rackspace Backup", :version => get_version } 
	end

	def run(message)

		pl = payload(message)
		@log.debug "Pruned payload #{pl}"

		@username 				= pl['username']
		@api_key 				= pl['api_key']
		@container 				= pl['container']
		@remote_path 		 	= pl['remote_path']
		@region					= pl['region']
		@keep 					= pl['keep'].empty? ? 0 : pl['keep'].to_i
		@local_pattern 			= pl['local_pattern']
		@testing				= pl['testing']

		return transfer
	end

	private

	def get_connection
		#Fog.mock! unless @testing.nil? || @testing == false	
		if @region == 'europe'
			connection = Fog::Storage.new(
  				:provider           	=> 'Rackspace',
  				:rackspace_username 	=> @username,
  				:rackspace_api_key  	=> @api_key,
  				:rackspace_auth_url 	=> "lon.auth.api.rackspacecloud.com"
				)
		else
			connection = Fog::Storage.new(
  				:provider           	=> 'Rackspace',
  				:rackspace_username 	=> @username,
  				:rackspace_api_key  	=> @api_key,
  				)
		end
		connection

	end

	def transfer
		begin
			#set up the rackspace connection
			@connection = get_connection
			if @keep <= 0
				sync_files_without_version_history
			else	
				sync_files_with_version_history
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
				return run_result(false, "Remote rackspace serivce or container not found (404)")
			elsif exc.response.status != 0
				return run_result(false, "Remote rackspace serivce returned error #{exc.response.status} without any more details")
			else
				return run_result(false, exc.message)
			end
		end
	end

	def remove_initial_slash(filename)
		filename.sub(/^\//, '')
	end

	def ensure_trailing_slash(filename)
		return "" if filename.empty?
		filename.sub(/\/$/, '') + '/'
	end

	def sync_files_without_version_history

		#prepare the remote directory variable
		@remote_path = remove_initial_slash(ensure_trailing_slash(@remote_path))
		count = 0

		#for each local file match
		Dir.glob(File.expand_path(@local_pattern)).each do |f|
				
			#skip to next match if current is a directory
			next if File.directory?(f)

			#assign the remote filename
			new_remote_filename = remove_initial_slash(File.join(@remote_path, f))
			@log.debug "Copying #{f} to #{new_remote_filename}"
			count += 1

			#push file to rackspace
			File.open(f, 'r') do |file| 
				@connection.put_object(@container, new_remote_filename, file) 
			end
		end

		return run_result(true, "Successully pushed #{count} file(s) to Rackspace Cloud Files container (without version history)")

	end

	def sync_files_with_version_history

		#prepare the remote directory variable
		@remote_path = remove_initial_slash(ensure_trailing_slash(@remote_path))
		count = 0

		#get remote directory
		directory = @connection.directories.get(@container)

		#cache the rackspace remote directory identifing all appropriate files
		remote_path_match = Regexp.new("^#{@remote_path}", "i")
		rackspace_directory = directory.files.map {|f| f.key }

		all_remote_files = rackspace_directory.select {|m| m =~ remote_path_match}.map {|m| remove_initial_slash(m.gsub(remote_path_match, ''))}
		archive_regex = /(?<folder>^Archive_Cloud66 \(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\)\/)/
		non_archive_files = all_remote_files.reject { |m| m =~ archive_regex }
		archived_files = all_remote_files.select { |m| m =~ archive_regex }

		new_archive_folder = "Archive_Cloud66 (#{Time.now.strftime("%Y-%m-%d %H:%M:%S")})/"
		
		#copy all non-archive files to new backup folder
		non_archive_files.each do |relative_file|

			puts "name is #{relative_file}"
			
			#move file to archive
			existing_remote_filename = remove_initial_slash(File.join(@remote_path, relative_file))
			new_remote_relative_filename = File.join(new_archive_folder, "#{relative_file}")
			new_remote_filename = remove_initial_slash(File.join(@remote_path, new_remote_relative_filename))
				
			@log.debug "Copying #{existing_remote_filename} to #{new_remote_filename}"
			@connection.copy_object @container, existing_remote_filename, @container, new_remote_filename
			
			@log.debug "Removing #{existing_remote_filename}"
			@connection.delete_object @container, existing_remote_filename

			#add newly archived file to list of archived files
			archived_files << new_remote_relative_filename
		end

		#copy up all new files from source
		all_local_files = Dir.glob(File.expand_path(@local_pattern))
		return run_result(true, "No file(s) identified to push to Rackspace Cloud Files container (with version history)") if all_local_files.size == 0
 
		#determine a local root to create relative files (TODO?)
		#local_root = ""
		#local_root_regex = Regexp.new local_root
		
		#copy all local matches up to rackspace
		all_local_files.each do |f|
			
			#skip to next match if current is a directory
			next if File.directory?(f)
				
			#assign the remote filename
			new_remote_filename = remove_initial_slash(File.join(@remote_path, f))
			@log.debug "Copying #{f} to #{new_remote_filename}"
			count += 1
			
			#push file to rackspace
			File.open(f, 'r') do |file|				
				@connection.put_object @container, new_remote_filename, file
			end

		end

		#get list of archive folders
		archive_folders = archived_files.map {|m| archive_regex.match(m)['folder']}.uniq.sort.reverse

		#if we have too many archive folders
		while archive_folders.size > @keep do
			archive_folder = archive_folders.delete_at(archive_folders.size-1)
			archive_regex = Regexp.new "^#{Regexp.escape(archive_folder)}", "i"
			
			#remove old archived files
			archived_files.select { |m| m =~ archive_regex }.each do |file|
				remote_file_to_remove = remove_initial_slash(File.join(@remote_path, file))
				@log.debug "Removing old archive file #{remote_file_to_remove}"
				@connection.delete_object @container, remote_file_to_remove
			end
		end

		return run_result(true, "Successully pushed #{count} file(s) to Rackspace Cloud Files container (with version history)")

	end

end	