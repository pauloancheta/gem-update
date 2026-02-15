# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "socket"

class RailsSmoke::TestPumaServer < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir("rails-smoke-puma-test")
    @log_dir = File.join(@tmpdir, "logs")
  end

  def teardown
    @server&.stop
    FileUtils.rm_rf(@tmpdir)
  end

  def test_initializes_with_port_and_log_dir
    server = RailsSmoke::PumaServer.new(port: 9292, log_dir: @log_dir)

    assert_equal 9292, server.port
    assert_nil server.pid
  end

  def test_initializes_with_env_hash
    env = { "RAILS_ENV" => "test", "DATABASE_URL" => "postgresql://localhost/mydb" }
    server = RailsSmoke::PumaServer.new(port: 9292, log_dir: @log_dir, env: env)

    assert_equal 9292, server.port
    assert_nil server.pid
  end

  def test_stop_without_start_is_safe
    server = RailsSmoke::PumaServer.new(port: 9292, log_dir: @log_dir)
    server.stop
    assert_nil server.pid
  end

  def test_start_creates_log_directory
    port = find_available_port
    @server = RailsSmoke::PumaServer.new(port: port, log_dir: @log_dir)

    write_rack_app

    @server.start(directory: @tmpdir)

    assert File.directory?(@log_dir)
    assert @server.pid
  ensure
    @server&.stop
  end

  def test_start_and_stop_lifecycle
    port = find_available_port
    @server = RailsSmoke::PumaServer.new(port: port, log_dir: @log_dir)

    write_rack_app

    @server.start(directory: @tmpdir)
    pid = @server.pid

    assert pid
    assert process_alive?(pid)

    @server.stop
    assert_nil @server.pid
  end

  def test_start_with_env_hash
    port = find_available_port
    env = { "RAILS_ENV" => "test", "RACK_ENV" => "test" }
    @server = RailsSmoke::PumaServer.new(port: port, log_dir: @log_dir, env: env)

    write_rack_app

    @server.start(directory: @tmpdir)

    assert @server.pid
    assert process_alive?(@server.pid)
  ensure
    @server&.stop
  end

  private

  def write_rack_app
    File.write(File.join(@tmpdir, "config.ru"), <<~RUBY)
      run ->(env) { [200, { "content-type" => "text/plain" }, ["OK"]] }
    RUBY

    File.write(File.join(@tmpdir, "Gemfile"), <<~RUBY)
      source "https://rubygems.org"
      gem "puma"
      gem "rackup"
    RUBY

    Bundler.with_unbundled_env do
      system("bundle", "install", chdir: @tmpdir, out: File::NULL, err: File::NULL)
    end
  end

  def find_available_port
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    server.close
    port
  end

  def process_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end
end
