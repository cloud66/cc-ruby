require File.join(File.dirname(__FILE__), 'quartz_plugin')
require 'fileutils'

class Logrotate < QuartzPlugin

	def info
		{ :uid => "8f4286bfd946c8b08b234833673b8860", :name => "Log Rotate", :version => "0.0.0" }
	end

	def run(message)
		pl = payload(message)

		@source_pattern 	= pl['source_pattern']
		@dest_folder 		= pl['destination']
		@keep 				= pl['keep'].empty? ? 0 : pl['keep'].to_i
		@post_run_step 		= pl['post_rotate']

        ext = Time.now.utc.strftime('%Y%m%d%H%M%S')

        FileUtils.mkdir_p(@dest_folder)

		Dir.glob(@source_pattern).each do |f|
			dest_file = File.join(@dest_folder, File.basename(f))
			next if File.directory?(f)
			fname = "#{dest_file}.gz"
			dump_cmd = "cat #{f} | gzip > '#{fname}.#{ext}'"
	        @log.debug "Running #{dump_cmd}"
	        copy_result = run_shell(dump_cmd)

	        return run_result(false, copy_result[:message]) unless copy_result[:ok]

	        @log.debug "Removing source log files"
	        remove_result = run_shell("rm #{f}")

	        return run_result(false, remove_result[:message]) unless remove_result[:ok]

	    	# find all the files from this one's rotations
	    	rotated_pattern = "#{fname}.*"
	    	@log.debug "Looking for rotated files #{rotated_pattern}"
	    	all_rotated = Dir.glob(rotated_pattern)
	    	if all_rotated.count > @keep
	    		remove_count = all_rotated.count - @keep
	        	to_remote = all_rotated.sort! { |a,b| File.mtime(a) <=> File.mtime(b) }[0...remove_count]
				@log.debug "Removing extra #{remove_count} files"
				to_remote.each do |tr|
					@log.debug "Removing #{tr}"
					remove_shell = run_shell("rm #{tr}")
					return run_result(false, remove_shell[:message]) unless remove_shell[:ok]
				end
	        end
        end

        if !@post_run_step.nil? && !@post_run_step.empty?
        	@log.debug "Running post rotate step #{@post_run_step}"
        	post_shell = run_shell(@post_run_step)
        	return run_result(false, post_shell[:message]) unless post_shell[:ok]
        end

        return run_result(true, "Log files rotated succesfully")
   	end
end	