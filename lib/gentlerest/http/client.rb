require "net/http"
require "addressable/uri"
require "gentlerest/version"
require "gentlerest/utilities/blank"
require "gentlerest/utilities/normalize"
require "gentlerest/http/request"
require "gentlerest/http/response"

module GentleREST
  class HttpClient
    # This error is raised whenever a resource is inaccessible over HTTP.
    class AccessError < StandardError
    end

    # Makes an HTTP request and returns the HTTP response.  Optionally
    # takes a block that determines whether or not to follow a redirect.
    # The block will be passed the HTTP redirect response as an argument.
    def self.request(http_operation, url, options={}, &block)
      response = nil
      options = {
        :request_headers => {
          "Accept" => "*/*",
          "User-Agent" =>
            "GentleREST/#{GentleREST::Version::STRING} " + 
            "+http://gentlerest.rubyforge.org/"},
        :previous_response_headers => {},
        :follow_redirects => true,
        :redirect_limit => 10,
        :response_history => [],
        :form_data => {}
      }.merge(options)
      
      http_operation = http_operation.to_s.downcase.to_sym
      
      if options[:redirect_limit] == 0
        raise HTTP::AccessError, 'Redirect too deep'
      end
      
      # Ensure valid, useable option values.
      if options[:response_history].blank? ||
          !options[:response_history].kind_of?(Array)
        options[:response_history] = []
      end
      if !options[:request_headers].kind_of?(Hash)
        options[:request_headers] = {}
      end
      if options[:request_headers].blank?
        options[:request_headers] = {}
      end
      
      if !options[:previous_response_headers].blank?
        if options[:previous_response_headers]['etag'] != nil
          options[:request_headers]["If-None-Match"] =
            options[:previous_response_headers]['etag']
        end
        if options[:previous_response_headers]['last-modified'] != nil
          options[:request_headers]["If-Modified-Since"] =
            options[:previous_response_headers]['last-modified']
        end
      end

      uri = Addressable::URI.parse(url).normalize

      begin
        proxy_address = options[:proxy_address] || nil
        proxy_port = options[:proxy_port].to_i || nil
        proxy_user = options[:proxy_user] || nil
        proxy_password = options[:proxy_password] || nil

        http = Net::HTTP::Proxy(
          proxy_address, proxy_port, proxy_user, proxy_password
        ).new(uri.host, uri.port)

        path = uri.path
        path += ('?' + uri.query) if uri.query

        request_params = [path, options[:request_headers]]
        if http_operation == :post
          options[:form_data] = {} if options[:form_data].blank?
          request_params << options[:form_data]
        end
        
        Thread.pass
        response = http.send(http_operation, *request_params)
        
        http_response = nil
        if response != nil
          http_response = GentleREST::HttpResponse.new
          http_response.status = response.code.to_i
          response.each_header do |header, value|
            corrected_header = 
              GentleREST::Normalization.http_header_normalize(header)
            http_response.headers[corrected_header] = value
          end
          http_response.body = response.body
          http_response.history = options[:response_history]
        end

        case response
        when Net::HTTPSuccess
        when Net::HTTPNotModified
        when Net::HTTPRedirection
          if response['Location'].nil?
            raise FeedAccessError,
              "No location to redirect to supplied for " + response.code
          end
          options[:response_history] << [url, http_response]

          redirected_location = response['Location']
          redirected_location =
            Addressable::URI.join(uri, redirected_location).normalize.to_s

          if options[:response_history].assoc(redirected_location) != nil
            raise HTTP::AccessError,
              "Redirection loop detected: #{redirected_location}"
          end

          # Let the block handle redirects
          follow_redirect = true
          if block != nil
            follow_redirect = block.call(redirected_location, response)
          end

          if follow_redirect
            response = GentleREST::HTTP.request(
              http_operation,
              redirected_location, 
              options.merge(
                {:redirect_limit => (options[:redirect_limit] - 1)}),
              &block)
          end
        end
      rescue SocketError
        raise HTTP::AccessError,
          "Socket error prevented resource retrieval: #{uri.to_s}"
      rescue Timeout::Error, Errno::ETIMEDOUT
        raise HTTP::AccessError,
          "Timeout while attempting to retrieve resource: #{uri.to_s}"
      rescue Errno::ENETUNREACH
        raise HTTP::AccessError,
          "Network was unreachable: #{uri.to_s}"
      rescue Errno::ECONNRESET
        raise HTTP::AccessError,
          "Connection was reset by peer: #{uri.to_s}"
      end

      if response != nil && !response.kind_of?(GentleREST::HttpResponse)
        return http_response
      elsif response != nil && response.kind_of?(GentleREST::HttpResponse)
        response.history = options[:response_history]
        return response
      else
        return nil
      end
    end
  end
end
