# frozen_string_literal: true

# Copied from apivore just to kept as an example
module Apivore
  # schema validators, not implemented
  class CustomSchemaValidator
    # This constant is an example custom schema included with the gem
    WF_SCHEMA = File.expand_path("./custom_schemata/westfield_api_standards.json", File.dirname(__FILE__))

    def initialize(custom_schema)
      @schema = custom_schema
    end

    def matches?(swagger_checker)
      @results = JSON::Validator.fully_validate(@schema, swagger_checker.swagger)
      @results.empty?
    end

    def description
      "additionally conforms to #{@schema}"
    end

    def failure_message
      @results.join("\n")
    end
  end
end
