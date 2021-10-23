require "mini_apivore/version"

module MiniApivore
  module Validation # former Validator

    class IndHash < Hash
      include Hashie::Extensions::MergeInitializer
      include Hashie::Extensions::IndifferentAccess
    end

    def prepare_action_env(verb, path, expected_response_code, params = {})
      @errors = []
      @verb = verb.to_s
      @path = path.to_s
      @params = IndHash.new(params)
      @expected_response_code = expected_response_code.to_i
    end

    def swagger_checker; self.class.swagger_checker end

    def check_route( verb, path, expected_response_code, params = {} )
      prepare_action_env( verb, path, expected_response_code, params )
      assert( match?, <<FAIL )
    Failed at: #{prepare_error_backtrace}\n
    Failure message: #{failure_message},\n 
    fullpath: #{full_path}, \n 
    params causing failure:#{params}
FAIL
    end

    def prepare_error_backtrace
      # it will deliver something like this:
      #"/app/test/helpers/base_routes_helpers.rb:57:in `__create_card'",
      #"/app/test/integration/cards_api_test.rb:71:in `block (2 levels) in <class:CommentsApiTest>'",
      Thread.current.backtrace[2..-1].slice_after{|trc| trc[/check_route/] }.to_a.last[0..1]
    end

    def match?
      #pre_checks
      check_request_path

      # request
      unless has_errors?
        send(
          @verb,
          *action_dispatch_request_args(
            full_path,
            params: @params['_data'] || {},
            headers: @params['_headers'] || {}
          )
        )

        #post_checks
        check_status_code
        check_response_is_valid unless has_errors?


        if has_errors? && response.body.length > 0
          @errors << "\nResponse body:\n #{JSON.pretty_generate(JSON.parse(response.body))}"
        end

        swagger_checker.remove_tested_end_point_response(
          @path, @verb, @expected_response_code
        )
      end
      !has_errors?
    end

    def check_request_path
      if !swagger_checker.has_path?(@path)
        @errors << "Swagger doc: #{swagger_checker.swagger_path} does not have"\
            " a documented @path for #{@path}"
      elsif !swagger_checker.has_method_at_path?(@path, @verb)
        @errors << "Swagger doc: #{swagger_checker.swagger_path} does not have"\
            " a documented @path for #{@verb} #{@path}"
      elsif !swagger_checker.has_response_code_for_path?(@path, @verb, @expected_response_code)
        @errors << "Swagger doc: #{swagger_checker.swagger_path} does not have"\
            " a documented response code of #{@expected_response_code} at @path"\
            " #{@verb} #{@path}. "\
            "\n             Available response codes: #{swagger_checker.response_codes_for_path(@path, @verb)}"
      elsif @verb == "get" && swagger_checker.fragment(@path, @verb, @expected_response_code).nil?
        @errors << "Swagger doc: #{swagger_checker.swagger_path} missing"\
            " response model for get request with #{@path} for code"\
            " #{@expected_response_code}"
      end
    end

    def full_path
      apivore_build_path(swagger_checker.base_path + @path, @params)
    end

    def apivore_build_path(path, data)
      path.scan(/\{([^\}]*)\}/).each do |param|
        key = param.first
        dkey = data && ( data[key] || data[key.to_sym] )
        if dkey
          path = path.gsub "{#{key}}", dkey.to_param.to_s
        else
          raise URI::InvalidURIError, "No substitution data found for {#{key}}"\
              " to test the path #{path}.", caller
        end
      end
      path + (data['_query_string'] ? "?#{data['_query_string'].to_param}" : '')
    end

    def has_errors?; !@errors.empty?  end

    def failure_message; @errors.join(" ") end

    def check_status_code
      if response.status != @expected_response_code
        @errors << "Path #{@path} did not respond with expected status code."\
            " Expected #{@expected_response_code} got #{response.status}"\
        end
    end

    def check_response_is_valid
      swagger_errors = swagger_checker.has_matching_document_for(
        @path, @verb, response.status, response_body
      )
      unless swagger_errors.empty?
        @errors.concat(
          swagger_errors.map do |e|
            e.sub("'#", "'#{full_path}#").gsub(
              /^The property|in schema.*$/,''
            )
          end
        )
      end
    end

    def response_body
      JSON.parse(response.body) if response.body && !response.body.empty?
    end

    def action_dispatch_request_args(path, params: {}, headers: {})
      if defined?(ActionPack) && ActionPack::VERSION::MAJOR >= 5
        [path, params: params, headers: headers]
      else
        [path, params, headers]
      end
    end
  end

end