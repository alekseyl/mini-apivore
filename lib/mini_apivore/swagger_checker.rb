require "mini_apivore/version"

module MiniApivore
  class SwaggerChecker
    PATH_TO_CHECKER_MAP = {}

    def self.instance_for(path)
      PATH_TO_CHECKER_MAP[path] ||= new(path)
    end

    def has_path?(path)
      mappings.has_key?(path)
    end

    def has_method_at_path?(path, verb)
      mappings[path].has_key?(verb)
    end

    def has_response_code_for_path?(path, verb, code)
      mappings[path][verb].has_key?(code.to_s)
    end

    def response_codes_for_path(path, verb)
      mappings[path][verb].keys.join(", ")
    end

    def has_matching_document_for(path, verb, code, body)
      JSON::Validator.fully_validate(
        swagger, body, fragment: fragment(path, verb, code)
      )
    end

    def fragment(path, verb, code)
      path_fragment = mappings[path][verb.to_s][code.to_s]
      path_fragment.dup unless path_fragment.nil?
    end

    def remove_tested_end_point_response(path, verb, code)
      return if untested_mappings[path].nil? ||
        untested_mappings[path][verb].nil?
      untested_mappings[path][verb].delete(code.to_s)
      if untested_mappings[path][verb].size == 0
        untested_mappings[path].delete(verb)
        if untested_mappings[path].size == 0
          untested_mappings.delete(path)
        end
      end
    end

    def base_path
      @swagger.base_path
    end

    def response=(response)
      @response = response
    end

    attr_reader :response, :swagger, :swagger_path

    def untested_mappings; @untested_mappings end
    def untested_mappings=( other ); @untested_mappings = other end

    private

    attr_reader :mappings

    def initialize(swagger_path)
      @swagger_path = swagger_path
      load_swagger_doc!
      validate_swagger!
      setup_mappings!
    end

    # сюда можно поставить замену для загрузки из файла данных, а не из рельс.
    def load_swagger_doc!
      @swagger = MiniApivore::Swagger.new(fetch_swagger!)
    end

    def fetch_swagger!
      if File.exist?( swagger_path )
        JSON.parse( File.read(swagger_path) )
      else
        session = ActionDispatch::Integration::Session.new(Rails.application)
        begin
          session.get(swagger_path)
        rescue
          fail "Unable to perform GET request for swagger json: #{swagger_path} - #{$!}."
        end
        JSON.parse(session.response.body)
      end
    end

    def validate_swagger!
      errors = swagger.validate
      unless errors.empty?
        msg = "The document fails to validate as Swagger #{swagger.version}:\n"
        msg += errors.join("\n")
        fail msg
      end
    end

    def setup_mappings!
      @mappings = {}
      @swagger.each_response do |path, verb, response_code, fragment|
        @mappings[path] ||= {}
        @mappings[path][verb] ||= {}
        raise "duplicate" unless @mappings[path][verb][response_code].nil?
        @mappings[path][verb][response_code] = fragment
      end

      self.untested_mappings = JSON.parse(JSON.generate(@mappings))
    end
  end
end
