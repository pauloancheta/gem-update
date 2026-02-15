# frozen_string_literal: true

require "test_helper"

class RailsSmoke::TestUpdate < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RailsSmoke::VERSION
  end
end
