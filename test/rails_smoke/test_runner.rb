# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class RailsSmoke::TestRunner < Minitest::Test
  def test_initializes_with_config
    tmpdir = Dir.mktmpdir("rails-smoke-runner-test")
    File.write(File.join(tmpdir, ".rails_smoke.yml"), YAML.dump("gem_name" => "rails"))

    config = RailsSmoke::Config.new(project_root: tmpdir)
    runner = RailsSmoke::Runner.new(config: config)

    assert_instance_of RailsSmoke::Runner, runner
  ensure
    FileUtils.rm_rf(tmpdir)
  end
end
