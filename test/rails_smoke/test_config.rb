# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class RailsSmoke::TestConfig < Minitest::Test # rubocop:disable Metrics/ClassLength
  def setup
    @tmpdir = Dir.mktmpdir("rails-smoke-config-test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_raises_when_no_config_file
    error = assert_raises(RailsSmoke::Error) do
      RailsSmoke::Config.new(project_root: @tmpdir)
    end

    assert_match(/Config file not found/, error.message)
  end

  def test_raises_when_gem_name_missing
    write_config("server" => true)

    error = assert_raises(RailsSmoke::Error) do
      RailsSmoke::Config.new(project_root: @tmpdir)
    end

    assert_match(/gem_name is required/, error.message)
  end

  def test_raises_when_gem_name_empty
    write_config("gem_name" => "  ")

    error = assert_raises(RailsSmoke::Error) do
      RailsSmoke::Config.new(project_root: @tmpdir)
    end

    assert_match(/gem_name is required/, error.message)
  end

  def test_reads_gem_name
    write_config("gem_name" => "rails")

    config = RailsSmoke::Config.new(project_root: @tmpdir)

    assert_equal "rails", config.gem_name
  end

  def test_defaults_with_minimal_config
    write_config("gem_name" => "rails")

    config = RailsSmoke::Config.new(project_root: @tmpdir)

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

    config = RailsSmoke::Config.new(project_root: @tmpdir)

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
    File.write(File.join(@tmpdir, ".rails_smoke.yml"), "")

    error = assert_raises(RailsSmoke::Error) do
      RailsSmoke::Config.new(project_root: @tmpdir)
    end

    assert_match(/gem_name is required/, error.message)
  end

  # --- Gem mode ---

  def test_gem_mode_detection
    write_config("gem_name" => "rails")

    config = RailsSmoke::Config.new(project_root: @tmpdir)

    assert_equal "gem", config.mode
  end

  def test_gem_mode_identifier
    write_config("gem_name" => "rails")

    config = RailsSmoke::Config.new(project_root: @tmpdir)

    assert_equal "rails", config.identifier
  end

  # --- Branch mode ---

  def test_branch_mode_with_both_branches
    write_config("before_branch" => "main", "after_branch" => "bump-rack-3.0")

    config = RailsSmoke::Config.new(project_root: @tmpdir)

    assert_equal "branch", config.mode
    assert_equal "main", config.before_branch
    assert_equal "bump-rack-3.0", config.after_branch
  end

  def test_branch_mode_identifier_is_after_branch
    write_config("before_branch" => "main", "after_branch" => "bump-rack-3.0")

    config = RailsSmoke::Config.new(project_root: @tmpdir)

    assert_equal "bump-rack-3.0", config.identifier
  end

  def test_branch_mode_defaults_before_branch_to_main
    write_config("after_branch" => "bump-rack-3.0")

    config = RailsSmoke::Config.new(project_root: @tmpdir)

    assert_equal "branch", config.mode
    assert_equal "main", config.before_branch
    assert_equal "bump-rack-3.0", config.after_branch
  end

  def test_branch_mode_defaults_after_branch_to_current_branch
    write_config("before_branch" => "main")

    config = RailsSmoke::Config.new(project_root: @tmpdir)

    assert_equal "branch", config.mode
    assert_equal "main", config.before_branch
    # after_branch defaults to current git branch
    refute_nil config.after_branch
    refute_empty config.after_branch
  end

  def test_branch_mode_no_gem_name
    write_config("before_branch" => "main", "after_branch" => "bump-rack-3.0")

    config = RailsSmoke::Config.new(project_root: @tmpdir)

    assert_nil config.gem_name
  end

  def test_raises_when_both_gem_name_and_branch_fields
    write_config("gem_name" => "rails", "after_branch" => "bump-rack-3.0")

    error = assert_raises(RailsSmoke::Error) do
      RailsSmoke::Config.new(project_root: @tmpdir)
    end

    assert_match(/Cannot set both gem_name and branch fields/, error.message)
  end

  def test_raises_when_gem_name_and_before_branch
    write_config("gem_name" => "rails", "before_branch" => "develop")

    error = assert_raises(RailsSmoke::Error) do
      RailsSmoke::Config.new(project_root: @tmpdir)
    end

    assert_match(/Cannot set both gem_name and branch fields/, error.message)
  end

  private

  def write_config(hash)
    File.write(File.join(@tmpdir, ".rails_smoke.yml"), YAML.dump(hash))
  end
end
