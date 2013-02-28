require 'sys/filesystem'
require 'socket'

class VitalSignsUtils

	def self.get_disk_usage_info
		space_info = {}
		Sys::Filesystem.mounts do |mount|
			stat = Sys::Filesystem.stat(mount.mount_point)

			#skip if this mount is not active
			#next if stat.blocks_available == 0 && stat.blocks == 0

			mb_free = Float(stat.block_size) * Float(stat.blocks_available) / 1000 / 1000
			mb_total = Float(stat.block_size) * Float(stat.blocks) / 1000 / 1000
			mb_used = mb_total - mb_free
			percent_used = mb_total > 0.0 ? mb_used / mb_total * 100 : 0.0

			space_info[mount.mount_point] = { mb_free: mb_free, mb_used: mb_used, mb_total: mb_total, percent_used: percent_used }
			mount.mount_point
		end
		return space_info
	rescue => exc
		@log.error "Failure during disk usage gathering due to #{exc}"
		return { invalid: exc.message }
	end

	def self.get_cpu_usage_info

		#NOTE: we can get core-level info with mpstat -P ALL 1 1
		#parse mpstat result
		mpstat_result = `mpstat 1 5`

#		mpstat_result = <<-SAMPLE
#Linux 3.2.0-23-generic (precise64) 	12/07/2012 	_x86_64_	(2 CPU)
#
#10:42:50 AM  CPU    %usr   %nice    %sys   %ddle    %irq   %soft  %steal  %guest   %idle
#10:42:51 AM  all    0.00    0.00    0.50    5.00    0.00    0.00    0.00    0.00   99.50
#Average:     all    0.00    0.00    0.50    50.00    0.00    0.00    0.00    0.00   99.50
#SAMPLE

#split output into lines
		lines = mpstat_result.split(/\r?\n/)

		#get rid of time (first 13 chars)
		lines = lines.map { |line| line[13..-1] }

		#get the header line and split into columns
		header_line = lines.detect { |line| line =~ /%idle/ }
		columns = header_line.split(/\s+/)

		#detect position of %idle column
		idle_index = columns.index('%idle')

		#get average line
		average_line = lines[-1]
		columns = average_line.split(/\s+/)

		#get idle value
		idle_string = columns[idle_index]
		idle_value = idle_string.to_f

		percent_used = 100.0 - idle_value

		#get average utilization value
		return { percent_used: percent_used, percent_free: idle_value }
	rescue => exc
		@log.error "Failure during CPU usage gathering due to #{exc}"
		return { invalid: exc.message }
	end

	def self.get_memory_usage_info
		free_m_result = `free -m`
#		free_m_result = <<-SAMPLE
#             total       used       free     shared    buffers     cached
#Mem:           590        480        109          0         37        227
#-/+ buffers/cache:        216        373
#Swap:            0          0          0
#SAMPLE

		free_m_result.each_line do |line|
			if line =~ /^Mem:/
				parts = line.scan(/.*?(\d+)/)
				parts.flatten!

				mb_total = parts[0].to_f
				# mb_used is not a true representation due to OS gobbling up mem
				# mb_used = parts[1].to_i
				mb_free = parts[2].to_f
				mb_shared = parts[3].to_f
				mb_buffers = parts[4].to_f
				mb_cached = parts[5].to_f

				#The total free memory available to proceses is calculated by adding up Mem:cached + Mem:buffers + Mem:free (99 + 63 + 296)
				#This then needs to be divided by Mem:total to get the total available free memory (1692)
				mb_available = mb_cached + mb_buffers + mb_free
				mb_used = mb_total - mb_available
				mb_free = mb_total - mb_used
				percent_used = mb_used / mb_total * 100
				return { mb_free: mb_free, mb_used: mb_used, mb_total: mb_total, percent_used: percent_used }
			end
		end
	rescue => exc
		@log.error "Failure during memory usage gathering due to #{exc}"
		return { invalid: exc.message }
	end

	def self.get_facter_info
		# facter command
		facter_text = `sudo facter`
		return parse_facter_text(facter_text)
	end

	def self.get_ip_address_info
		# facter command for ip information (collect up to 5 local ip addresses)

		facter_text = `facter ipaddress ec2_public_ipv4 ipaddress_eth0 ipaddress6 ipaddress6_eth0`
		ip_hash = parse_facter_text(facter_text)

		result = {}

		if ip_hash.has_key?('ec2_public_ipv4')
			# return ec2 info first (most specific)
			result[:ext_ipv4] = ip_hash['ec2_public_ipv4']
		elsif ip_hash.has_key?('ipaddress')
			# return ipaddress next (general)
			result[:ext_ipv4] = ip_hash['ipaddress']
		end
		result[:int_ipv4] = ip_hash['ipaddress_eth0'] if ip_hash.has_key?('ipaddress_eth0')
		result[:ext_ipv6] = ip_hash['ipaddress6'] if ip_hash.has_key?('ipaddress6')
		result[:int_ipv6] = ip_hash['ipaddress6_eth0'] if ip_hash.has_key?('ipaddress6_eth0')

		# don't have any ip address info
		return {} if result.empty?
		# return ip address info
		return { :ip_addresses => result }
	end

	# parse the factor text, not using YAML due to YAML parsing issues, and facter JSON output not working
	def self.parse_facter_text(facter_text)
		facter_hash = {}
		facter_text.lines.each do |line|
			split = line.split('=>')
			key = split[0]
			if split.size == 2
				value = split[1]
				if !value.nil?
					value = value.strip
					# exclude empty or long results (like ssh keys)
					if !value.empty? && value.size < 100
						key = key.strip
						facter_hash[key] = value
					end
				end
			end
		end
		return facter_hash
	end
end


