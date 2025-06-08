# frozen_string_literal: true

require "English"
require "mini_apivore/version"

module MiniApivore
  class SwaggerChecker
    PATH_TO_CHECKER_MAP = {}.freeze

    def self.instance_for(path, schema = {})
      PATH_TO_CHECKER_MAP[path] ||= new(path, schema)
    end

    def has_path?(path)
      mappings.key?(path)
    end

    def has_method_at_path?(path, verb)
      mappings[path].key?(verb)
    end

    def has_response_code_for_path?(path, verb, code)
      mappings[path][verb].key?(code.to_s)
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
      path_fragment&.dup
    end

    def remove_tested_end_point_response(path, verb, code)
      return if untested_mappings[path].nil? ||
                untested_mappings[path][verb].nil?

      untested_mappings[path][verb].delete(code.to_s)
      return unless untested_mappings[path][verb].empty?

      untested_mappings[path].delete(verb)
      untested_mappings.delete(path) if untested_mappings[path].empty?
    end

    def base_path
      @swagger.base_path
    end

    attr_accessor :response, :untested_mappings
    attr_reader :swagger, :swagger_path

    private

    attr_reader :mappings

    def initialize(swagger_path, schema)
      @swagger_path = swagger_path
      @schema = schema
      load_swagger_doc!
      validate_swagger!
      setup_mappings!
    end

    # сюда можно поставить замену для загрузки из файла данных, а не из рельс.
    def load_swagger_doc!
      @swagger = MiniApivore::Swagger.new(fetch_swagger!)
    end

    def fetch_swagger!
      return @schema unless @schema.empty?

      if File.exist?(swagger_path)
        JSON.parse(File.read(swagger_path))
      else
        session = ActionDispatch::Integration::Session.new(Rails.application)
        begin
          session.get(swagger_path)
        rescue StandardError
          raise "Unable to perform GET request for swagger json: #{swagger_path} - #{$ERROR_INFO}."
        end
        JSON.parse(session.response.body)
      end
    end

    def validate_swagger!
      errors = swagger.validate
      return if errors.empty?

      msg = "The document fails to validate as Swagger #{swagger.version}:\n"
      msg += errors.join("\n")
      raise msg
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
