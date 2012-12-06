require 'sys/filesystem'
require 'socket'
require 'open-uri'

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

	def self.get_network_info

		address_infos = Socket.ip_address_list
		private_ip_addresses = address_infos.select { |intf| intf.ipv4_private? }.map { |address| address.ip_address }
		public_ip_addresses = address_infos.select { |intf| intf.ipv4? and !intf.ipv4_loopback? and !intf.ipv4_multicast? and !intf.ipv4_private? }.map { |address| address.ip_address }

		ipaddr = UDPSocket.open {|s| s.connect('65.59.196.211'); s.addr.last }

	end

end

