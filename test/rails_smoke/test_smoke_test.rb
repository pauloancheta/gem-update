# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class RailsSmoke::TestSmokeTest < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @tmpdir = File.realpath(Dir.mktmpdir("rails-smoke-smoke-test"))
    Dir.chdir(@tmpdir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_discovers_files_in_smoke_directory
    FileUtils.mkdir_p("test/smoke")
    File.write("test/smoke/boot.rb", 'puts "boot"')
    File.write("test/smoke/routes.rb", 'puts "routes"')

    smoke = RailsSmoke::SmokeTest.new("myapp")
    files = smoke.test_files
    assert_includes files, File.join(@tmpdir, "test/smoke/boot.rb")
    assert_includes files, File.join(@tmpdir, "test/smoke/routes.rb")
  end

  def test_discovers_files_in_subdirectories
    FileUtils.mkdir_p("test/smoke/models")
    File.write("test/smoke/boot.rb", 'puts "boot"')
    File.write("test/smoke/models/user.rb", 'puts "user"')

    smoke = RailsSmoke::SmokeTest.new("myapp")
    files = smoke.test_files
    assert_includes files, File.join(@tmpdir, "test/smoke/boot.rb")
    assert_includes files, File.join(@tmpdir, "test/smoke/models/user.rb")
  end

  def test_no_test_files
    smoke = RailsSmoke::SmokeTest.new("myapp")
    assert_empty smoke.test_files
  end

  def test_run_with_no_tests_returns_failure
    output_dir = File.join(@tmpdir, "output")
    smoke = RailsSmoke::SmokeTest.new("myapp")
    result = smoke.run(directory: @tmpdir, output_dir: output_dir)

    refute result.success
    assert_match(/No smoke tests found/, result.stderr)
  end

  def test_run_writes_runtime_config_with_server_port
    FileUtils.mkdir_p("test/smoke")
    File.write("test/smoke/myapp.rb", <<~'RUBY')
      require "yaml"
      config = YAML.safe_load_file(ARGV[0])
      puts "PORT=#{config["server_port"]}"
    RUBY

    File.write("Gemfile", 'source "https://rubygems.org"')
    system("bundle", "install", "--quiet", out: File::NULL, err: File::NULL)

    output_dir = File.join(@tmpdir, "output")
    smoke = RailsSmoke::SmokeTest.new("myapp")
    result = smoke.run(directory: @tmpdir, output_dir: output_dir, server_port: 4000)

    assert_match(/PORT=4000/, result.stdout)
  end

  def test_run_writes_runtime_config_with_output_dir
    FileUtils.mkdir_p("test/smoke")
    File.write("test/smoke/myapp.rb", <<~RUBY)
      require "yaml"
      config = YAML.safe_load_file(ARGV[0])
      File.write(File.join(config["output_dir"], "test.log"), "logged")
    RUBY

    File.write("Gemfile", 'source "https://rubygems.org"')
    system("bundle", "install", "--quiet", out: File::NULL, err: File::NULL)

    output_dir = File.join(@tmpdir, "output")
    smoke = RailsSmoke::SmokeTest.new("myapp")
    smoke.run(directory: @tmpdir, output_dir: output_dir)

    assert File.exist?(File.join(output_dir, "smoke", "test.log"))
    assert_equal "logged", File.read(File.join(output_dir, "smoke", "test.log"))
  end

  def test_runtime_config_omits_server_port_when_nil
    FileUtils.mkdir_p("test/smoke")
    File.write("test/smoke/myapp.rb", <<~'RUBY')
      require "yaml"
      config = YAML.safe_load_file(ARGV[0])
      puts "has_port=#{config.key?("server_port")}"
    RUBY

    File.write("Gemfile", 'source "https://rubygems.org"')
    system("bundle", "install", "--quiet", out: File::NULL, err: File::NULL)

    output_dir = File.join(@tmpdir, "output")
    smoke = RailsSmoke::SmokeTest.new("myapp")
    result = smoke.run(directory: @tmpdir, output_dir: output_dir)

    assert_match(/has_port=false/, result.stdout)
  end
end
