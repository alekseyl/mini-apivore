# frozen_string_literal: true

require "test_helper"

class InitializationTest < ActionDispatchMocker
  def load_schema
    JSON.parse(File.read(File.expand_path("../data/01_sample2.0.json", __dir__)))
  end

  def load_sym_schema
    load_schema.transform_keys(&:to_sym)
  end

  test "hash with symbolic keys init is OK" do
    MiniApivore::SwaggerChecker.instance_for("", load_sym_schema)
  end

  test "base methods will match for sym schema and str schema" do
    sym_swg = MiniApivore::Swagger.new(load_sym_schema)
    str_swg = MiniApivore::Swagger.new(load_schema)
    assert_equal(sym_swg.version, str_swg.version)
    assert_equal(sym_swg.base_path, str_swg.base_path)
  end
end

# didn't implement custom schema for now
#
#   describe "a swagger document not conforming to a custom schema" do
#     it 'should fail the additional validation' do
#       stdout = `rspec spec/data/example_specs.rb --example 'fails custom validation'`
#       expect(stdout).to match(/1 failure/)
#       expect(stdout).to include("The property '#/definitions/service' did not contain a required property of 'type'")
#     end
#   end
# end

# test "fails custom validation" do
#   subject { Apivore::SwaggerChecker.instance_for("/08_untyped_definition.json") }
#   it "passes" do
#     expect(subject).to validate(:get, "/services.json", 200)
#   end
#
#   it "fails" do
#     expect(subject).to conform_to(Apivore::CustomSchemaValidator::WF_SCHEMA)
#   end
# end
# end
