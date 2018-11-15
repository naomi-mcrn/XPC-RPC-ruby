require 'json'
require 'net/http'
require 'net/https'
require 'base64'
require_relative 'commands'
require_relative 'errors'

module XPC
  module RPC
    class Client
      def initialize(options)
        @opts = {
          host:   'localhost',
          port:   40080,
          method: 'POST',
          user: '',
          pass: '',
          headers: {
            'Authorization' => ''
          },
          passphrasecallback: nil,
          https: false,
          ca: nil
        }
        
        if options
          self.set(options)
        end
        self
      end
      
      def invalid(command)
        puts "No such command #{command}"
      end
      
      def sendrpc(command,*args)
        rpcData = {
          id: (Time.now.to_f * 1000).to_i,
          method: command.downcase,
          params: args
          }.to_json
        
        options = @opts
        
        http = Net::HTTP.new(options[:host],options[:port])
        http.read_timeout = nil #NO TIMEOUT!!
        req = nil
        if options[:method].upcase == "POST"
          req = Net::HTTP::Post.new("/")
          req.body = rpcData
          req["Content-Type"] = "application/json"
          options[:headers].each do |k,v|
            if v.to_s != ""
              req[k] = v
            end
          end
        else
          raise #GET not support...
        end
        
        if options[:https] == true
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        
        res = http.request(req)
        data = nil
        errmsg = nil
        begin
          data = JSON.parse(res.body)
        rescue
          if res.code.to_i != 200
            errmsg = "Invalid params #{res.code}"
          else
            errmsg = "Failed to parse JSON"
          end
          errmsg += " : #{res.body.to_json}"
          puts errmsg
          return false
        end
        
        if data["error"]
          errcode = data['error']['code'].to_i
          # if errcode == XPC::RPC::Error::RPC_WALLET_UNLOCK_NEEDED && options['passphrasecallback']
          #   return self.unlock(command,*args) 
          #else
            errname = XPC::RPC::Error.constants.select{|x| XPC::RPC::Error.const_get(x) == errcode}[0].to_s
            puts "Command error : #{errname}(#{errcode})"
          #end
        end
        return data
      end
      
      def execrpc(command,*args)
        if XPC::RPC::command?(command)
          self.sendrpc(command,*args)
        else
          self.invalid(command,*args)
        end
      end
      
      def auth(user, pass)
        if user && pass
          authString = "Basic " + Base64.encode64("#{user}:#{pass}").chomp
          @opts[:headers]['Authorization'] = authString
        end
        nil
      end
      
      def unlock(command,*args)
        raise 'not implemented'
      end
      
      def set(k,v=nil)
        if k.respond_to?(:each)
          k.each do |kk,vv|
            self.set(kk,vv)
          end
          return
        end
        
        k = k.to_s.downcase.to_sym
        if @opts.has_key?(k)
          @opts[k] = v
          if /^(user|pass)$/ =~ k
            self.auth(@opts[:user],@opts[:pass])
          end
        end
        return self
      end
      
      def get(k)
        if @opts[k] == false
          return false
        else
          if @opts[k] != false
            return @opts[k.downcase]
          else
            return nil
          end
        end
      end
    end
  end
end
