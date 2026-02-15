# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class Gem::TestRunner < Minitest::Test
  def test_initializes_with_config
    tmpdir = Dir.mktmpdir("gem-update-runner-test")
    File.write(File.join(tmpdir, ".gem_update.yml"), YAML.dump("gem_name" => "rails"))

    config = Gem::Update::Config.new(project_root: tmpdir)
    runner = Gem::Update::Runner.new(config: config)

    assert_instance_of Gem::Update::Runner, runner
  ensure
    FileUtils.rm_rf(tmpdir)
  end
end
