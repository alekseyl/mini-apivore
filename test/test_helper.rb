# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "mini_apivore"
require "mini_apivore/declarative"

require "minitest/autorun"
require "mini_apivore/action_dispatch_mocker"
require "json"
