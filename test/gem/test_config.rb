# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class Gem::TestConfig < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir("gem-update-config-test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_raises_when_no_config_file
    error = assert_raises(Gem::Update::Error) do
      Gem::Update::Config.new(project_root: @tmpdir)
    end

    assert_match(/Config file not found/, error.message)
  end

  def test_raises_when_gem_name_missing
    write_config("server" => true)

    error = assert_raises(Gem::Update::Error) do
      Gem::Update::Config.new(project_root: @tmpdir)
    end

    assert_match(/gem_name is required/, error.message)
  end

  def test_raises_when_gem_name_empty
    write_config("gem_name" => "  ")

    error = assert_raises(Gem::Update::Error) do
      Gem::Update::Config.new(project_root: @tmpdir)
    end

    assert_match(/gem_name is required/, error.message)
  end

  def test_reads_gem_name
    write_config("gem_name" => "rails")

    config = Gem::Update::Config.new(project_root: @tmpdir)

    assert_equal "rails", config.gem_name
  end

  def test_defaults_with_minimal_config
    write_config("gem_name" => "rails")

    config = Gem::Update::Config.new(project_root: @tmpdir)

    refute config.server?
    assert_equal 3000, config.before_port
    assert_equal 3001, config.after_port
    assert_equal "test", config.rails_env
    assert config.sandbox?
    assert_nil config.version
    assert_nil config.setup_task
    assert_nil config.setup_script
    assert_nil config.database_url_base
  end

  def test_overrides_defaults
    write_config(
      "gem_name" => "rails",
      "server" => true,
      "before_port" => 5000,
      "after_port" => 5001,
      "version" => "7.2.0",
      "sandbox" => false,
      "rails_env" => "staging",
      "setup_task" => "db:seed",
      "setup_script" => "test/smoke/seed.rb",
      "database_url_base" => "postgresql://localhost"
    )

    config = Gem::Update::Config.new(project_root: @tmpdir)

    assert config.server?
    assert_equal 5000, config.before_port
    assert_equal 5001, config.after_port
    assert_equal "7.2.0", config.version
    refute config.sandbox?
    assert_equal "staging", config.rails_env
    assert_equal "db:seed", config.setup_task
    assert_equal "test/smoke/seed.rb", config.setup_script
    assert_equal "postgresql://localhost", config.database_url_base
  end

  def test_empty_yaml_file_raises
    File.write(File.join(@tmpdir, ".gem_update.yml"), "")

    error = assert_raises(Gem::Update::Error) do
      Gem::Update::Config.new(project_root: @tmpdir)
    end

    assert_match(/gem_name is required/, error.message)
  end

  private

  def write_config(hash)
    File.write(File.join(@tmpdir, ".gem_update.yml"), YAML.dump(hash))
  end
end
