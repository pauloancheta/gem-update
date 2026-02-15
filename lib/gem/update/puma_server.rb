# frozen_string_literal: true

require "socket"
require "fileutils"

module Gem
  module Update
    class PumaServer
      READY_TIMEOUT = 30
      READY_POLL_INTERVAL = 0.5

      attr_reader :port, :pid

      def initialize(port:, log_dir:)
        @port = port
        @log_dir = log_dir
        @pid = nil
      end

      def start(directory:)
        FileUtils.mkdir_p(@log_dir)

        stdout_log = File.join(@log_dir, "puma_stdout.log")
        stderr_log = File.join(@log_dir, "puma_stderr.log")

        @pid = Bundler.with_unbundled_env do
          Process.spawn(
            "bundle", "exec", "puma", "-p", @port.to_s,
            chdir: directory,
            out: stdout_log,
            err: stderr_log
          )
        end

        wait_for_ready
      end

      def stop
        return unless @pid

        Process.kill("TERM", @pid)
        Process.wait(@pid)
      rescue Errno::ESRCH, Errno::ECHILD
        # Process already exited
      ensure
        @pid = nil
      end

      private

      def wait_for_ready
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + READY_TIMEOUT

        while Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
          return if port_open?

          sleep READY_POLL_INTERVAL
        end

        raise "Puma server failed to start on port #{@port} within #{READY_TIMEOUT}s"
      end

      def port_open?
        socket = TCPSocket.new("127.0.0.1", @port)
        socket.close
        true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        false
      end
    end
  end
end
