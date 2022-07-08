# frozen_string_literal: true

require "test_helper"

module LastTestMocker
  def teardown
    super
    CorrectResponsesTest.new("final tester").check_for_final_test if MiniApivore.all_test_ran?
  end
end

class UnimplementedPathTest < ActionDispatchMocker
  include MiniApivore
  include LastTestMocker

  init_swagger(File.expand_path("../data/02_unimplemented_path.json", __dir__))

  test "unimplemented_path" do
    prepare_action_env(:get, "/not_implemented.json", 200)
    match?
    assert(@errors.length == 1)
    assert(@errors[0] == "Path /not_implemented.json did not respond with expected status code. Expected 200 got 404")
  end
end

class ToParam
  def to_param
    1
  end
end

class ToParamIntTest < ActionDispatchMocker
  include MiniApivore
  include LastTestMocker

  init_swagger(File.expand_path("../data/03_mismatched_type_response.json", __dir__))

  test "to param as int" do
    prepare_action_env(:get, "/services/{id}.json", 200, "id" => ToParam.new)
    match?
    assert(@errors[0] == " '/api/services/1.json#/name' of type string did not match"\
      " one or more of the following types: integer, null ")
  end
end

class MismatchedTypeTest < ActionDispatchMocker
  include MiniApivore
  include LastTestMocker

  init_swagger(File.expand_path("../data/03_mismatched_type_response.json", __dir__))

  test "mismatched property" do
    prepare_action_env(:get, "/services.json", 200)
    match?
    assert(@errors[0] == " '/api/services.json#/0/name' of type string did not match"\
      " one or more of the following types: integer, null ")

    prepare_action_env(:get, "/services/{id}.json", 200, "id" => 1)
    match?
    assert(@errors[0] == " '/api/services/1.json#/name' of type string did not match"\
      " one or more of the following types: integer, null ")
  end
end

class UnexpectedHttpTest < ActionDispatchMocker
  include MiniApivore
  include LastTestMocker

  init_swagger(File.expand_path("../data/04_unexpected_http_response.json", __dir__))

  test "unxepected http property" do
    prepare_action_env(:get, "/services.json", 222)
    match?
    assert(@errors[0] == "Path /services.json did not respond with expected status code. Expected 222 got 200")
  end
end

class ExtraPropertiesTest < ActionDispatchMocker
  include MiniApivore
  include LastTestMocker

  init_swagger(File.expand_path("../data/05_extra_properties.json", __dir__))

  test "extra property" do
    prepare_action_env(:get, "/services.json", 200)
    match?
    assert(@errors[0] == " '/api/services.json#/0' contains additional properties [\"name\"]"\
      " outside of the schema when none are allowed ")

    prepare_action_env(:get, "/services/{id}.json", 200, "id" => 1)
    match?
    assert(@errors[0] == " '/api/services/1.json#/' contains additional properties [\"name\"]"\
      " outside of the schema when none are allowed ")
  end
end

class MissingPropertiesTest < ActionDispatchMocker
  include MiniApivore
  include LastTestMocker

  init_swagger(File.expand_path("../data/06_missing_required_property.json", __dir__))

  test "extra property" do
    prepare_action_env(:get, "/services.json", 200)
    match?
    assert(@errors[0] == " '/api/services.json#/0' did not contain a required property of 'test_required' ")

    prepare_action_env(:get, "/services/{id}.json", 200, "id" => 1)
    match?
    assert(@errors[0] == " '/api/services/1.json#/' did not contain a required property of 'test_required' ")
  end
end

class MissingNonRequiredPropertiesTest < ActionDispatchMocker
  include MiniApivore
  include LastTestMocker

  init_swagger(File.expand_path("../data/07_missing_non-required_property.json", __dir__))

  test "extra property" do
    prepare_action_env(:get, "/services.json", 200)
    assert(match?, "Must pass when property not required")

    prepare_action_env(:get, "/services/{id}.json", 200, "id" => 1)
    assert(match?, "Must pass when property not required")
  end
end

class CorrectResponsesTest < ActionDispatchMocker
  include MiniApivore
  include LastTestMocker

  init_swagger(File.expand_path("../data/01_sample2.0.json", __dir__))

  test "correct API" do
    check_route(:post, "/services.json", 204, "name" => "hello world")
    check_route(:get, "/services/{id}.json", 200, "id" => 1)

    check_route(:put, "/services/{id}.json", 204, "id" => 1)
    check_route(:delete, "/services/{id}.json", 204, "id" => 1)

    # p MiniApivore.runnable_list

    check_route(:patch, "/services/{id}.json", 204, "id" => 1)

    # will be tested last before real final test
    # check_route( :get, "/services.json", 200 )
  end

  def check_for_final_test
    assert(MiniApivore.prepare_untested_errors.length == 1)
    assert(MiniApivore.prepare_untested_errors[0] == "get /services.json is untested for"\
      " response code 200 in test class CorrectResponsesTest")

    check_route(:get, "/services.json", 200)
    assert(MiniApivore.prepare_untested_errors.empty?)
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
