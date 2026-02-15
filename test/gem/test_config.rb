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

  def test_defaults_when_no_file
    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    refute config.server?
    assert_equal 3000, config.before_port
    assert_equal 3001, config.after_port
  end

  def test_reads_defaults_from_yaml
    write_config("defaults" => { "server" => true, "before_port" => 5000, "after_port" => 5001 })

    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert config.server?
    assert_equal 5000, config.before_port
    assert_equal 5001, config.after_port
  end

  def test_gem_specific_overrides
    write_config(
      "defaults" => { "server" => false, "before_port" => 3000, "after_port" => 3001 },
      "rails" => { "server" => true, "before_port" => 4000, "after_port" => 4001 }
    )

    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert config.server?
    assert_equal 4000, config.before_port
    assert_equal 4001, config.after_port
  end

  def test_gem_override_partial_merge
    write_config(
      "defaults" => { "server" => true, "before_port" => 3000, "after_port" => 3001 },
      "rails" => { "before_port" => 4000 }
    )

    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert config.server?
    assert_equal 4000, config.before_port
    assert_equal 3001, config.after_port
  end

  def test_unmatched_gem_uses_defaults
    write_config(
      "defaults" => { "server" => true },
      "rails" => { "before_port" => 4000 }
    )

    config = Gem::Update::Config.new("sidekiq", project_root: @tmpdir)

    assert config.server?
    assert_equal 3000, config.before_port
    assert_equal 3001, config.after_port
  end

  def test_version_from_gem_override
    write_config(
      "rails" => { "version" => "7.2.0" }
    )

    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert_equal "7.2.0", config.version
  end

  def test_version_defaults_to_nil
    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert_nil config.version
  end

  def test_rails_env_defaults_to_test
    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert_equal "test", config.rails_env
  end

  def test_rails_env_override
    write_config("rails" => { "rails_env" => "staging" })

    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert_equal "staging", config.rails_env
  end

  def test_sandbox_defaults_to_true
    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert config.sandbox?
  end

  def test_sandbox_can_be_disabled
    write_config("rails" => { "sandbox" => false })

    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    refute config.sandbox?
  end

  def test_setup_task_defaults_to_nil
    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert_nil config.setup_task
  end

  def test_setup_task_from_config
    write_config("rails" => { "setup_task" => "db:seed" })

    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert_equal "db:seed", config.setup_task
  end

  def test_setup_script_defaults_to_nil
    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert_nil config.setup_script
  end

  def test_setup_script_from_config
    write_config("rails" => { "setup_script" => "test/smoke/seed.rb" })

    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert_equal "test/smoke/seed.rb", config.setup_script
  end

  def test_database_url_base_defaults_to_nil
    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert_nil config.database_url_base
  end

  def test_database_url_base_from_config
    write_config("defaults" => { "database_url_base" => "postgresql://localhost" })

    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    assert_equal "postgresql://localhost", config.database_url_base
  end

  def test_empty_yaml_file
    File.write(File.join(@tmpdir, ".gem_update.yml"), "")

    config = Gem::Update::Config.new("rails", project_root: @tmpdir)

    refute config.server?
    assert_equal 3000, config.before_port
    assert_equal 3001, config.after_port
  end

  private

  def write_config(hash)
    File.write(File.join(@tmpdir, ".gem_update.yml"), YAML.dump(hash))
  end
end
