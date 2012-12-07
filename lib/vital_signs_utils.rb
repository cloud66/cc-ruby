require 'sys/filesystem'
require 'socket'

class VitalSignsUtils

	def self.get_disk_usage_info
		space_info = { }
		Sys::Filesystem.mounts do |mount|
			stat = Sys::Filesystem.stat(mount.mount_point)

			#skip if this mount is not active
			#next if stat.blocks_available == 0 && stat.blocks == 0

			mb_free = Float(stat.block_size) * Float(stat.blocks_available) / 1000 / 1000
			mb_total = Float(stat.block_size) * Float(stat.blocks) / 1000 / 1000
			mb_used = mb_total - mb_free
			percent_used =  mb_total > 0.0 ? mb_used / mb_total * 100 : 0.0

			space_info[mount.mount_point] = { mb_free: mb_free, mb_used: mb_used, mb_total: mb_total, percent_used: percent_used }
			mount.mount_point
		end
		return space_info
	end

	def self.get_cpu_usage_info

		#NOTE: we can get core-level info with mpstat -P ALL 1 1
		#parse mpstat result
		mpstat_result = `mpstat 1 10`

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
		header_line = lines.detect {|line| line =~ /%idle/}
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
	end

	def self.get_memory_usage_info

		#parse sar result
		sar_result = `sar -r 1 10`

#		sar_result = <<-SAMPLE
#Linux 3.2.0-31-virtual (ip-10-30-159-183) 	12/07/2012 	_x86_64_	(2 CPU)
#
#12:23:38 PM kbmemfree kbmemused  %memused kbbuffers  kbcached  kbcommit   %commit  kbactive   kbinact
#12:23:39 PM    436404   1296860     74.82     68204    693436    959636     36.20    800452    385916
#12:23:40 PM    436156   1297108     74.84     68204    693436    959704     36.20    800436    385916
#12:23:41 PM    436164   1297100     74.84     68204    693436    959704     36.20    800376    385916
#12:23:42 PM    436032   1297232     74.84     68204    693436    959704     36.20    800520    385916
#12:23:43 PM    436048   1297216     74.84     68204    693436    959704     36.20    800496    385916
#12:23:44 PM    436032   1297232     74.84     68204    693436    959704     36.20    800440    385916
#12:23:45 PM    436040   1297224     74.84     68204    693436    959704     36.20    800520    385916
#12:23:46 PM    436040   1297224     74.84     68204    693436    959704     36.20    800436    385916
#12:23:47 PM    436040   1297224     74.84     68204    693436    959704     36.20    800436    385916
#12:23:48 PM    436048   1297216     74.84     68204    693436    959704     36.20    800436    385916
#Average:       436100   1297164     74.84     68204    693436    959697     36.20    800455    385916
#SAMPLE

		#split output into lines
		lines = sar_result.split(/\r?\n/)

		#get rid of time (first 13 chars)
		lines = lines.map { |line| line[12..-1].strip unless line[12..-1].nil?  }

		#get the header line and split into columns
		header_line = lines.detect {|line| line =~ /kbmemfree/}
		columns = header_line.split(/\s+/)

		#detect positions of memfree and memused columns
		mem_free_index = columns.index('kbmemfree')
		mem_used_index = columns.index('kbmemused')

		#get average line
		average_line = lines[-1]
		columns = average_line.split(/\s+/)

		#get values in mb
		mb_free_string = columns[mem_free_index]
		mb_free = mb_free_string.to_f / 1024
		mb_used_string = columns[mem_used_index]
		mb_used = mb_used_string.to_f / 1024
		mb_total = mb_free + mb_used
		percent_used = mb_used / mb_total * 100

		#get average utilization value
		return { mb_free: mb_free, mb_used: mb_used, mb_total: mb_total, percent_used: percent_used }
	end

	def self.get_network_info
		address_infos = Socket.ip_address_list
		private_ip_addresses = address_infos.select { |intf| intf.ipv4_private? }.map { |address| address.ip_address }
		public_ip_addresses = address_infos.select { |intf| intf.ipv4? and !intf.ipv4_loopback? and !intf.ipv4_multicast? and !intf.ipv4_private? }.map { |address| address.ip_address }
		return { network: { private: private_ip_addresses, public: public_ip_addresses } }
	end
end


