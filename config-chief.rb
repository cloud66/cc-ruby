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
    self.class.base_uri options[:url] || 'http://localhost:3000/api/v1'
  end
  
  def get_value(key, options = {}, params = {} )
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

cc = ConfigChief.new(:api_key => "92647a801ab5e9d94066abfb9f34ef4a", :workspace => "06b8a8ba1309e6253a3d53ec5486737b")
#puts cc.get_value('a.b.c')
#puts cc.set_value('x.y.z', 'zibzib')
#puts cc.register_node(:node_type_id => 5, :node_name => 'from api', :node_timezone => 'UTC')
puts cc.unregister_node('83fb99f4a84aabffeb79a02c5a944a15')
#puts cc.update_node_status('83fb99f4a84aabffeb79a02c5a944a15', 1)
#puts cc.config_items