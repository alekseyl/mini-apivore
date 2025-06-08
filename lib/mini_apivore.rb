# frozen_string_literal: true

require "json-schema"
require "mini_apivore/version"
require "mini_apivore/fragment"
require "mini_apivore/swagger"
require "mini_apivore/swagger_checker"
require "mini_apivore/validation"
require "mini_apivore/http_codes"
require "mini_apivore/to_param"

module MiniApivore
  SWAGGER_CHECKERS = {}.freeze
  #----- Module globals -----------------
  def self.runnable_list
    @@runnable_list ||= [] # rubocop:disable Style/ClassVars
  end

  def self.all_test_ran?
    runnable_list.empty?
  end

  def self.prepare_untested_errors
    errors = []
    SWAGGER_CHECKERS.each do |cls, chkr|
      chkr.untested_mappings.each do |path, methods|
        methods.each do |method, codes|
          codes.each_key do |code|
            errors << "#{method} #{path} is untested for response code #{code} in test class #{cls}"
          end
        end
      end
    end
    errors
  end

  def self.included(base)
    base.extend(ClassMethods)
    base.include(MiniApivore::Validation)
  end

  #---- class methods -----------
  module ClassMethods
    def init_swagger(swagger_path, schema = "")
      SWAGGER_CHECKERS[self] ||= MiniApivore::SwaggerChecker.instance_for(swagger_path, schema)
    end

    def runnable_methods
      super | ["final_test"]
    end

    def test(name, &block)
      super(name, &block).tap { |sym| MiniApivore.runnable_list << "#{self}::#{sym}" }
    end

    def swagger_checker
      SWAGGER_CHECKERS[self]
    end
  end

  #----- Minitest callback -----------
  def teardown
    super
    MiniApivore.runnable_list.delete("#{self.class}::#{@NAME}")
  end

  #----- test for untested routes ---------
  def final_test
    # whenever we running tests with inheritance from some base class with dedicated schema,
    # we will run final_test multiple times, one per ancestor
    # so we need to assert something to eliminate warnings about zero assertions in a final_test
    return assert(true) unless MiniApivore.all_test_ran?

    @errors = MiniApivore.prepare_untested_errors
    assert(@errors.empty?, @errors.join("\n"))

    # preventing duplicate execution
    MiniApivore.runnable_list << "#{self.class}::#{__method__}_runned"
  end
end
