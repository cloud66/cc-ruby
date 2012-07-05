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
		@region					= pl['region']
		@container 				= pl['container']
		@remote_directory 		= pl['remote_directory'].sub(/^\//, '')
		@local_pattern 			= pl['local_pattern']
		@keep 					= pl['keep'].empty? ? 0 : pl['keep'].to_i

		@testing				= pl['testing']

		return transfer
	end

	private

	def get_connection
		#Fog.mock! unless @testing.nil? || @testing == false	
		if @region == 'Europe'
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

	def sync_files_without_version_history

		count = 0

		#for each local file match
		Dir.glob(File.expand_path(@local_pattern)).each do |f|
				
			#skip to next match if current is a directory
			next if File.directory?(f)
						
			#the filepaths file name
			local_filename = File.basename(f)

			#assign the remote filename
			new_remote_filename = File.join(@remote_directory, local_filename).sub(/^\//, '')
			@log.debug "Attempting to copy #{f} to #{new_remote_filename}"

			count += 1
			
			#push file to rackspace
			File.open(f, 'r') do |file| 
				@connection.put_object(@container, new_remote_filename, file) 
			end
			
			@log.debug "Successfully copied #{f} to #{new_remote_filename}"
		end

		return run_result(true, "Successully pushed #{count} file(s) to rackspace cloud files bucket (without version history)")

	end

	def sync_files_with_version_history

		count = 0

		#get remote directory
		directory = @connection.directories.get(@container)

		#cache the rackspace remote directory
		rackspace_directory = directory.files.map {|f| f.key }
		puts 'rackspace directory'
		puts rackspace_directory
	
		#identify all non-archive files
		remote_directory_match = Regexp.new("^#{@remote_directory}", "i")
		all_remote_files = rackspace_directory.map {|m| m.gsub(remote_directory_match, '').sub(/^\//, '')}
		puts 'rackspace directory'
		puts rackspace_directory
	

		puts 'all remote files'
		puts all_remote_files
		
		#TODO!
		archive_regex = /(?<folder>^archive \(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\)\/)/
		non_archive_files = all_remote_files.reject { |m| m =~ archive_regex }
		puts 'non archived files'
		puts non_archive_files

		new_archive_folder = "archive (#{Time.now.strftime("%Y-%m-%d %H:%M:%S")})"

		#copy all non-archive files to new backup folder
		non_archive_files.each do |relative_file|
			
			#move remove file to archive
			existing_remote_filename = File.join(@remote_directory, relative_file).sub(/^\//, '')
			
			##puts "existing --> #{existing_remote_filename}"

			new_remote_filename = File.join(new_archive_folder, "#{relative_file}")
			
			##puts "new --> #{new_remote_filename}"

			new_remote_filename = File.join(@remote_directory, new_remote_filename).sub(/^\//, '')
				
			@log.debug "copying #{existing_remote_filename} to #{new_remote_filename}"
			@connection.copy_object @container, existing_remote_filename, @container, new_remote_filename
			
			@log.debug "removing #{existing_remote_filename}"
			@connection.delete_object @container, existing_remote_filename
		end

		#copy up all new files from source
		#for each local file match
		first = true
		local_root = ""

		Dir.glob(File.expand_path(@local_pattern)).each do |f|
			
			if first && !File.directory?(f)
				local_root = File.dirname(f)
				puts "local root is #{local_root}"
				local_root_regex = Regexp.new("^#{local_root}", "i")
			end
			first = false

			#skip to next match if current is a directory
			next if File.directory?(f)
				
			#the filepaths file name
			if local_root.empty?
				local_file = f
			else 
				local_file = f.sub(local_root_regex, '')
			end

			count += 1
			File.open(f, 'r') do |file|
				new_remote_filename = File.join(@remote_directory, local_file).sub(/^\//, '')
				@log.debug "Attempting to copy #{f} to #{new_remote_filename}"
				#push file to rackspace
				@connection.put_object @container, new_remote_filename, file
				@log.debug "Successfully copied #{f} to #{new_remote_filename}"
			end

		end

		#get oldest archive folder (note not uploaded files yet)
		archived_files = all_remote_files.select { |m| m =~ archive_regex }
		archive_folders = archived_files.map { |m| archive_regex.match(m)['folder'] }.uniq.sort

		puts "a #{archive_folders}"

		return



		#identify all of the files on rackspace that have the same 'directory' as @remote_path 
		#create case insensitive regex match for directory
		file_match_regex = Regexp.new("^#{@remote_directory}", "i")
		remote_files = rackspace_directory.select { |m| file_match_regex =~ File.dirname(m) }
		#remove the remote directory component of the remote file
		remote_files = remote_files.map {|m| m.sub(file_match_regex, '')}


		remote_files_with_archive = Hash.new(remote_files.size)
		#for each relative remote file, check if there is already version history
		remote_files.each do |remote_file|
			archive_regex = Regexp.new("^archive/#{remote_file}", "i")
			archive_files = rackspace_directory.select { |m| archive_regex =~ m }
			remote_files_with_archive[remote_file] = archive_files
		end		

		count = 0

		#for each local file match
		Dir.glob(File.expand_path(@local_pattern)).each do |f|
			
			#local_root_directory
			local_root_directory ||= File.dirname(f)
			local_root_directory_regex ||= Regexp.new("^#{local_root_directory}", "i")

			#skip to next match if current is a directory
			next if File.directory?(f)
				
			#the filepaths file name
			#local_filename = File.basename(f)
			relative_file = f.sub(local_root_directory_regex, '')

			if remote_files_with_archive.include? relative_file
				
				#move remove file to archive
				existing_remote_filename = File.join(@remote_directory, relative_file).sub(/^\//, '')
				new_remote_filename = "archive/#{local_relative_file}__#{}"
				new_remote_filename = File.join(@remote_directory, new_remote_filename).sub(/^\//, '')
				
				@log.debug "moving #{existing_remote_filename} to #{new_remote_filename}"
				@connection.copy_object @container, existing_remote_filename, @container, new_remote_filename
				
				@log.debug "deleting #{existing_remote_filename}"
				archive_files = remote_files_with_archive[local_relative_file]
				


				#if archive_files.size > @keep



			else
				count += 1
				File.open(f, 'r') do |file|
					#remove preceding '/\' from @remote_path
					#safe_remote_path = @remote_path.sub(/^\//, '')
					new_remote_filename = File.join(@remote_directory, local_relative_file).sub(/^\//, '')
					@log.debug "Attempting to copy #{f} to #{new_remote_filename}"
					#push file to rackspace
					@connection.put_object @container, new_remote_filename, file
					@log.debug "Successfully copied #{f} to #{new_remote_filename}"
				end
			end


			


			#if the archive directory is already on the history limit, delete oldest one
			#then we need to move it to an archive folder





			#skip if we already have this file remotely and want to keep histor
			#unless existing_remote_filenames.include? local_filename
			#	count += 1
		#		File.open(f, 'r') do |file|
					#remove preceding '/\' from @remote_path
					#safe_remote_path = @remote_path.sub(/^\//, '')
			#		new_remote_filename = File.join(@remote_path, local_filename)
			#		@log.debug "Attempting to copy #{f} to #{new_remote_filename}"
					#push file to rackspace
			#		@connection.put_object(@container, new_remote_filename, file)	
		#			@log.debug "Successfully copied #{f} to #{new_remote_filename}"
		#		end
				
		#	end
		end

		
			#@log.debug "Found #{existing_remote_files.count} in the remote bucket"
			#if existing_remote_files.count > @keep
			#	remove_count = existing_remote_files.count - @keep
			#	@log.debug "Removing #{remove_count} and keeping the most recent #{@keep}"
			#	to_remove = existing_remote_files.sort { |a,b| a.last_modified <=> b.last_modified }.map{|m| m.key }[0...remove_count]
			#	@log.debug "Removing extra files"
			#	to_remove.each do |tr|
			#		@log.debug "Removing #{tr}"
			#		connection.delete_object(@bucket, tr)
			#	end
			#end
	end

end	