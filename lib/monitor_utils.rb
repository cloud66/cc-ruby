require 'sys/filesystem'
require 'socket'
require 'open-uri'

class MonitorUtils

	def self.get_free_space_info

		space_info = {}
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

end

