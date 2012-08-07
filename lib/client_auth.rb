class ClientAuth

	def initialize api_key, secret_key
		@headers = self.class.build_headers api_key, secret_key
	end

	def outgoing(message, callback)
 
    	# Again, leave non-subscribe messages alone
    	if message['channel'] != '/meta/subscribe'
    		return callback.call(message)
    	end

    	# Add ext field if it's not present	
    	message['ext'] ||= {}

    	# Set the tokens
    	message['ext']['api_key'] = @headers['api_key']
    	message['ext']['hash'] = @headers['hash']
    	message['ext']['time'] = @headers['time']

    	# Carry on and send the message to the server
    	callback.call(message)
    end

    def self.build_headers api_key, secret_key
		time = Time.now.utc.to_i
		hash = Digest::SHA1.hexdigest("#{api_key}#{secret_key}#{time}").downcase
		{ 'api_key' => api_key, 'hash' => hash, 'time' => time.to_s }
	end

end
