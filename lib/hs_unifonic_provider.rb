require 'hs_unifonic_provider/error_codes'
require "hs_unifonic_provider/mobile_number_normalizer"

module HsUnifonicProvider
  
  def self.supported_methods 
    ['send_sms', 'query_sms', 'get_balance']
  end

  def self.send_sms(credentials, mobile_number, message,sender,options = nil)
    connection = Faraday.new(:url => credentials[:server]) do |faraday|
      faraday.adapter Faraday.default_adapter
    end
    username = credentials[:username]
    password = credentials[:password]
    mobile = HsUnifonicProvider::MobileNumberNormalizer.normalize_number(mobile_number,'mobicents')
    uri = URI("/mobicents/sendSms")
    params = {userid: username, password: password, to: mobile , sender: sender, format: 'json', messageBodyEncoding: 'UTF8', smscEncoding: 'UCS2', msg: message}
    response = connection.get do |req|
      req.url uri.path
      req.params = params
    end
    if response.status.to_i.in?(200..299)
      message_id = response.body.gsub(/[^a-z,.:_,\-, ,^A-Z,0-9]/, "").split(',')[1].split(':')[1]
      return {message_id: message_id , code: 0}
    else
      return {error: response.body, code: response.status.to_i}
    end
  end

  def self.get_balance(credentials)
    connection = Faraday.new(:url => credentials[:server]) do |faraday|
      faraday.adapter Faraday.default_adapter
      faraday.headers['Content-Type'] = 'application/x-www-form-urlencoded'
    end
    appsid = credentials['password']
    uri = URI("/rest/Account/GetBalance")
    params = {body: "AppSid=#{appsid}"}
    response = connection.get do |req|
      req.url uri.path
      req.params = params
    end
    if response.code.to_i >= 200 && response.code.to_i < 300 && JSON.parse(response.body)["success"] == "true"
      return { balance: JSON.parse(response.body)["data"]["Balance"].to_i, code: nil }
    else
      result = HsUnifonicProvider::ErrorCodes.get_error_code(JSON.parse(response.body)["errorCode"])
      raise result[:error]
      return result
    end
  end

  def self.query_sms(credentials, message_id)
    connection = Faraday.new(:url => credentials[:server]) do |faraday|
      faraday.adapter Faraday.default_adapter
      faraday.headers['Content-Type'] = 'application/x-www-form-urlencoded'
    end
    uri = URI("/rest/Messages/GetMessageIDStatus")
    params = {AppSid: credentials['password'], MessageID: message_id}
    response = connection.get do |req|
      req.url uri.path
      req.params = params
    end

    if response.code.to_i >= 200 && response.code.to_i < 300 && JSON.parse(response.body)["success"] == "true"
      return { result: JSON.parse(response.body)["data"]["Status"], code: 0 }
    elsif response.code.to_i >= 200 && response.code.to_i <= 300 && JSON.parse(response.body)["Status"] == "Sent"
      return { result: "Sent", code: 1 }
    else
      result = HsUnifonicProvider::ErrorCodes.get_error_code(JSON.parse(response.body)["errorCode"])
      raise result[:error]
      return result
    end
  end



end
