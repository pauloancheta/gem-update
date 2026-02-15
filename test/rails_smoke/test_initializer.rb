# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class RailsSmoke::TestInitializer < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir("rails-smoke-init-test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_creates_config_file
    initializer = RailsSmoke::Initializer.new(project_root: @tmpdir)

    assert_output(/Created .rails_smoke.yml/) do
      initializer.run
    end

    config_path = File.join(@tmpdir, ".rails_smoke.yml")
    assert File.exist?(config_path)

    content = File.read(config_path)
    assert_match(/gem_name: CHANGE_ME/, content)
  end

  def test_creates_smoke_directory
    initializer = RailsSmoke::Initializer.new(project_root: @tmpdir)

    assert_output(%r{Created test/smoke/}) do
      initializer.run
    end

    assert Dir.exist?(File.join(@tmpdir, "test", "smoke"))
  end

  def test_skips_existing_config
    File.write(File.join(@tmpdir, ".rails_smoke.yml"), "gem_name: rails\n")

    initializer = RailsSmoke::Initializer.new(project_root: @tmpdir)

    assert_output(/already exists/) do
      initializer.run
    end

    assert_equal "gem_name: rails\n", File.read(File.join(@tmpdir, ".rails_smoke.yml"))
  end

  def test_skips_existing_smoke_dir
    FileUtils.mkdir_p(File.join(@tmpdir, "test", "smoke"))

    initializer = RailsSmoke::Initializer.new(project_root: @tmpdir)

    assert_output(%r{test/smoke/ already exists}) do
      initializer.run
    end
  end
end
