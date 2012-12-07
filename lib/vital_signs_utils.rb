require 'sys/filesystem'
require 'socket'

class VitalSignsUtils

	def self.get_free_space_info
		space_info = { }
		Sys::Filesystem.mounts do |mount|
			stat = Sys::Filesystem.stat(mount.mount_point)

			#skip if this mount is not active
			#next if stat.blocks_available == 0 && stat.blocks == 0

			mb_free = Float(stat.block_size) * Float(stat.blocks_available) / 1000 / 1000
			mb_total = Float(stat.block_size) * Float(stat.blocks) / 1000 / 1000

			space_info[mount.mount_point] = { mb_free: mb_free, mb_total: mb_total }
			mount.mount_point
		end
		return space_info
	end

	def self.get_cpu_usage_info

		#NOTE: we can get core-level info with mpstat -P ALL 1 1
		#parse mpstat result
		mpstat_result = `mpstat 1 1`

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

		#get average utilization value
		return 100.0 - idle_value
	end

	def self.get_network_info
		address_infos = Socket.ip_address_list
		private_ip_addresses = address_infos.select { |intf| intf.ipv4_private? }.map { |address| address.ip_address }
		public_ip_addresses = address_infos.select { |intf| intf.ipv4? and !intf.ipv4_loopback? and !intf.ipv4_multicast? and !intf.ipv4_private? }.map { |address| address.ip_address }
		return { network: { private: private_ip_addresses, public: public_ip_addresses } }
	end
end


