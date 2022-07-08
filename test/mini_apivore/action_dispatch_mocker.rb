# frozen_string_literal: true

# Boilerplate
class ActionDispatchMocker < Minitest::Test
  extend ActiveSupport::Testing::Declarative

  [:get, :post, :patch, :put, :delete].each do |name|
    define_method(name) do |route, _params, _headers|
      call(
        Hashie::Mash.new(
          PATH_INFO: route,
          REQUEST_METHOD: name.to_s.upcase
        )
      )
    end
  end

  def call(env)
    path = env["PATH_INFO"]
    method = env["REQUEST_METHOD"]
    test_swagger_files = [
      "/02_unimplemented_path.json",
      "/03_mismatched_type_response.json",
      "/04_unexpected_http_response.json",
      "/05_extra_properties.json",
      "/06_missing_required_property.json",
      "/07_missing_non-required_property.json",
      "/08_untyped_definition.json",
    ]

    case "#{method} #{path}"
    when "GET /api/services.json"
      respond_with(200, [{ id: 1, name: "hello world" }].to_json)
    when "POST /api/services.json"
      respond_with(204)
    when "GET /api/services/1.json"
      respond_with(200, { id: 1, name: "hello world" }.to_json)
    when "PUT /api/services/1.json"
      respond_with(204)
    when "DELETE /api/services/1.json"
      respond_with(204)
    when "PATCH /api/services/1.json"
      respond_with(204)
    else
      if test_swagger_files.include?(path)
        respond_with(200, File.read(File.expand_path("../../data#{path}", __FILE__)))
      else
        respond_with(404)
      end
    end
  end

  def respond_with(status_code, data = "")
    @response = Hashie::Mash.new(
      status: status_code,
      body: data
    )
  end

  attr_reader :response
end
