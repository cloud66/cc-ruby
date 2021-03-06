require File.join(File.dirname(__FILE__), 'quartz_plugin')
require 'fileutils'

class FileRotate < QuartzPlugin

        @@version_major = 0
        @@version_minor = 0
        @@version_revision = 1

	def info
		{ :uid => "02f7d8237bcc438e8f0659babfef2911", :name => "File Rotater", :version => get_version }
	end

	def run(message)
		pl = payload(message)

		source_pattern = pl['source_pattern']
		dest_folder = pl['location']
		keep = pl['keep'].nil? ? 5 : pl['keep'].to_i
		post_rotate = pl['post_rotate']

		archive = File.join(dest_folder, '/archive')

        ext = Time.now.utc.strftime('%Y%m%d%H%M%S')

        FileUtils.mkdir_p(archive)
        rotated = false
        Dir.glob(source_pattern).each do |f|
        	rotated = true
        	fname = File.basename(f)
        	dest_filename = "#{fname}.#{ext}"
        	dest_path = File.join(archive, dest_filename)
        	@log.debug "Moving #{f} to #{dest_path}"

        	move_shell = run_shell("mv #{f} #{dest_path}")
        	return run_result(false, move_shell[:message]) unless move_shell[:ok]

                return run_result(true, "Files moved successfully with no rotation") if keep == 0

        	# find all the files from this one's rotations
        	rotated_pattern = "#{File.join(archive, fname)}.*"
        	@log.debug "Looking for rotated files #{rotated_pattern}"
        	all_rotated = Dir.glob(rotated_pattern)
        	if all_rotated.count > keep
        		remove_count = all_rotated.count - keep
	        	to_remote = all_rotated.sort! { |a,b| File.mtime(a) <=> File.mtime(b) }[0...remove_count]
			@log.debug "Removing extra files"
			to_remote.each do |tr|
				@log.debug "Removing #{tr}"
				remove_shell = run_shell("rm #{tr}")
				return run_result(false, remove_shell[:message]) unless remove_shell[:ok]
			end
	        end
        end

        if !post_rotate.empty? && rotated
        	@log.debug "Running post rotate step #{post_rotate}"
        	post_shell = run_shell(post_rotate)
        	return run_result(false, post_shell[:message]) unless post_shell[:ok]
        end

        result = rotated ? "Files rotated successfully" : "No files to rotate"

        run_result(true, result)
	end
end