# encoding: utf-8

module Agent
	class Version

		##
		# Change the MAJOR, MINOR and PATCH constants below
		# to adjust the version of the Cloud66 Agent gem
		#
		# MAJOR:
		#  Defines the major version
		# MINOR:
		#  Defines the minor version
		# PATCH:
		#  Defines the patch version
		MAJOR, MINOR, PATCH  = 0, 0, 23

		#ie. PRERELEASE_MODIFIER = 'beta1'
		PRERELEASE_MODIFIER = 'pre'

		##
		# Returns the major version ( big release based off of multiple minor releases )
		def self.major
			MAJOR
		end

		##
		# Returns the minor version ( small release based off of multiple patches )
		def self.minor
			MINOR
		end

		##
		# Returns the patch version ( updates, features and (crucial) bug fixes )
		def self.patch
			PATCH
		end

		##
		# Returns the prerelease modifier ( not quite ready for public consumption )
		def self.prerelease_modifier
			PRERELEASE_MODIFIER
		end

		##
		# Returns the current version of the Backup gem ( qualified for the gemspec )
		def self.current
			prerelease_modifier.nil? ? "#{major}.#{minor}.#{patch}" : "#{major}.#{minor}.#{patch}.#{prerelease_modifier}"
		end

	end
end
