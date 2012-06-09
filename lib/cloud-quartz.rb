require 'httparty'
require 'json'

class CloudQuartz
	include HTTParty
	@api_key = ""
	@agent_id = ""
	
	def initialize(options = {})
		@api_key = options[:api_key]
		@agent_id = options[:agent_id]
		@secret_key = options[:secret_key]
		self.class.base_uri options[:url] || 'https://api.thecloudblocks.com'
	end

	def get_job
		process(self.class.get("/queue/#{@agent_id}.json", { :headers => http_headers } ))
	end

	def register(agent)
		process(self.class.post('/agent.json', { :headers => http_headers.merge({'Content-Type' => 'application/json'}), :body => agent.to_json }))
	end

	def unregister(agent)
		process(self.class.delete("/agent/#{@agent_id}.json", :headers => http_headers))
	end

	def check_version
		self.class.get("/agent/version", :headers => http_headers)
	end

	def post_results(job_id, data)
		process(self.class.post("/job/#{job_id}/complete.json", { :headers => http_headers.merge({'Content-Type' => 'application/json'}), :body => data.to_json } ))
	end

	def pulse
		process(self.class.get("/agent/#{@agent_id}/pulse.json", { :headers => http_headers } ))
	end

	def status(stat, version, plugins)
		data = { :status => stat, :version => version, :plugins => plugins }
		process(self.class.post("/agent/#{@agent_id}/status.json", { :headers => http_headers.merge({'Content-Type' => 'application/json'}), :body => data.to_json }))
	end

	private

	def http_headers
		time = Time.now.utc.to_i
		{ 'api_key' => @api_key, 'hash' => signature(time), 'time' => time.to_s }
	end

	def signature(time)
		Digest::SHA1.hexdigest("#{@api_key}#{@secret_key}#{time}")
	end

	def process(response)
		if response.code != 200
			raise response.body
		else
			response.parsed_response
		end
	end
end


