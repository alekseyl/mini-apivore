# frozen_string_literal: true

require "mini_apivore/version"

module MiniApivore
  # This is a workaround for json-schema's fragment validation which does not allow paths to contain forward slashes
  #  current json-schema attempts to split('/') on a string path to produce an array.
  class Fragment < Array
    def split(_options = nil)
      self
    end
  end
end
