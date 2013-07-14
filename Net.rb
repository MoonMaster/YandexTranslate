require 'net/http'
require 'addressable/uri'
require 'join'
require 'json'
require 'rubygems'

module YandexTranslate
class Connection
  $API_URL = 'https://translate.yandex.net/api/v1.5/tr'
  $API_KEY = 'trnsl.1.1.20130530T134155Z.7984d4327a90c37e.8ef8321bd864ab228a50b3477d674c59b4fae82e'
  attr_accessor :api_key, :api_url, :http, :API_URL, :API_URL
   UR = URI.parse("https://translate.yandex.net/api/v1.5/tr/")
  def get(url, params = {})
    self.request(:get, url, params)
  end

  def post()
    self.request(:post, params)
  end

  def put ()
    self.request(:put, params) 
  end

  def delete()
    self.request(:delete,params)
  end

  def initialize(key, url)
    self.api_key = key
    self.api_url = url.is_a?(URI) ? url : URI.parse(url)
    self.http = Net::HTTP.new(self.api_url.host, self.api_url.port)
    self.http.use_ssl = true
  end

  protected

  def request(type, url, params = {})
    ur = Addressable::URI.new
    params.merge!("key" => $API_KEY)
    ur.query_values = params
    if (self.api_url.path[-1] != '.json')
      self.api_url.path += '.json/'
    end
    url = self.api_url.path + url + ur.to_s
    response = (self.http.send(type, url).body)
    YandexTranslate::Parser.new(response).parse
    
  end
end
end

module YandexTranslate
 
  class Client
    def initialize()
      @connection  = Connection.new($API_KEY, $API_URL)
    end
    
    def get_lang()
      @connection.get('getLangs')["dirs"]
    end
    
    def detect(text = '')
      @connection.get('detect', { "text" => text })['lang']
    end
    
    def translate(text='', trans='')
      @connection.get('translate',{"lang"=> trans, "text"=> text})['text']
    end
  end
end

module YandexTranslate
  class Parser 
    def initialize(body)
      @body = body
    end

    def parse
      json = JSON.parse(@body)
      if (json.has_key?("code"))
        case json["code"].to_i
        when 401
          raise DetecteError.new(401, "Invalide api key")          
        # when 200
        #   raise DetecteError.new("Operation performed")
        when 402
          raise DetecteError.new(402,"Api key is locked")
        when 403
          raise DetecteError.new(403,"Exceeded the daily limit on the number of requests")
        when 404
          raise DetecteError.new(404,"Exceeded the daily limit on the amount of translated text")
        when 413
          raise DetecteError.new(413,"Exceeds the maximum size of the text.")
        when 422
          raise DetecteError.new(422,"The text can not be translated.")
        when 501
          raise DetecteError.new(501,"Set direction of transfer is not supported.")
        end          
      end

      return json
    end
  end
end

module YandexTranslate 

  class DetecteError < StandardError
    attr_accessor :code

    def initialize(code, text='')
      self.code = code

      super(text)
    end
  end

end
