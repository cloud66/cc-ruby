require 'HTTParty'
require 'socket'
require 'json'

class ConfigChief
  include HTTParty

  @api_key = ""
  @workspace = ""
  
  def initialize(options = {})
    @api_key = options[:api_key]
    @workspace = options[:workspace]
    self.class.base_uri options[:url] || 'https://api.thecloudblocks.com'
  end
  
  def get_by_key(key, options = {}, params = {})
    opts = {
      :default_value => nil,
      :full_obj => false
    }.merge(options)
    
    optionals = {}
    params.each do |k, v|
      optionals["cc-#{k}"] = v
    end
    
    headers = { :headers => http_headers.merge(optionals) }
    
    result = self.class.get("/workspaces/#{@workspace}/value.json", headers.merge(:query => { :query => key } ))
    
    if result.response.code.to_i == 200
      retrieved = result.parsed_response 
      return retrieved if opts[:full_obj]
      return retrieved['parsed_value']
    end
    
    return opts[:default_value]
  end

  def get_by_id(id, options = {}, params = {})
    opts = {
      :default_value => nil,
      :full_obj => false
    }.merge(options)
    
    optionals = {}
    params.each do |k, v|
      optionals["cc-#{k}"] = v
    end
    
    headers = { :headers => http_headers.merge(optionals) }
    
    result = self.class.get("/workspaces/#{@workspace}/config_keys/#{id}.json", headers )
    
    if result.response.code.to_i == 200
      retrieved = result.parsed_response 
      return retrieved if opts[:full_obj]
      return retrieved['parsed_value']
    end
    
    return opts[:default_value]
  end
  
  def workspaces
    self.class.get("/workspaces.json", { :headers => http_headers } )
  end
  
  def config_items(query = '*')
    headers = { :headers => http_headers }
    self.class.get("/workspaces/#{@workspace}/config_keys.json", headers.merge(:query => { :query => query } ))
  end
  
  def set_value(key, value)
    headers = { :headers => http_headers.merge({'Content-Type' => 'application/json'}) }
    self.class.post("/workspaces/#{@workspace}/config_keys.json", headers.merge(:body => { :key => key, :value => value }.to_json))
  end
  
  def register_node(options = {})
    headers = { :headers => http_headers.merge({'Content-Type' => 'application/json'}) }
    self.class.post("/workspaces/#{@workspace}/node.json", headers.merge(:body => options.to_json))
  end

  def unregister_node(node_uid)
    headers = { :headers => http_headers }
    self.class.delete("/workspaces/#{@workspace}/node/#{node_uid}.json", headers)
  end
  
  def update_node_status(node_uid, status)
    headers = { :headers => http_headers.merge({'Content-Type' => 'application/json'}) }
    self.class.post("/workspaces/#{@workspace}/node/#{node_uid}/status.json", headers.merge({ :body => { :status => status}.to_json}))
  end
  
  private 
  
  def http_headers
    { 'api_key' => @api_key, 'ConfigChief-Node' => Socket.gethostname }
  end
  
end