# frozen_string_literal: true

require "fileutils"

module Gem
  module Update
    class Runner
      def initialize(gem_name, config: nil)
        @gem_name = gem_name
        @config = config || Config.new(gem_name)
        @output_dir = File.join("tmp", "gem_updates", gem_name)
      end

      def run
        setup_output_dir

        puts "== gem-update: #{@gem_name} =="
        puts ""

        puts "1. Creating worktree..."
        worktree = Worktree.new(@gem_name, base_dir: @output_dir)
        worktree.create

        puts "2. Running bundle update #{@gem_name}..."
        updater = GemUpdater.new(@gem_name, worktree_path: worktree.path, output_dir: @output_dir)
        unless updater.run
          warn "bundle update #{@gem_name} failed. Check #{@output_dir}/bundle_update.log"
          cleanup(worktree)
          exit 1
        end

        before_server = nil
        after_server = nil
        smoke_env = {}

        begin
          if @config.server?
            puts "   Starting puma servers..."
            before_server = PumaServer.new(port: @config.before_port, log_dir: File.join(@output_dir, "before"))
            after_server = PumaServer.new(port: @config.after_port, log_dir: File.join(@output_dir, "after"))

            before_server.start(directory: Dir.pwd)
            puts "   Before server running on port #{@config.before_port}"

            after_server.start(directory: worktree.path)
            puts "   After server running on port #{@config.after_port}"

            smoke_env = {
              "BEFORE_PORT" => @config.before_port.to_s,
              "AFTER_PORT" => @config.after_port.to_s
            }
          end

          puts "3. Running smoke tests (before)..."
          smoke = SmokeTest.new(@gem_name)
          before_result = smoke.run(directory: Dir.pwd, output_dir: File.join(@output_dir, "before"), env: smoke_env)

          puts "4. Running smoke tests (after)..."
          after_dir = File.join(@output_dir, "after")
          after_result = smoke.run(directory: worktree.path, output_dir: after_dir, env: smoke_env)
        ensure
          before_server&.stop
          after_server&.stop
        end

        puts "5. Generating report..."
        report = Report.new(@gem_name, before: before_result, after: after_result, output_dir: @output_dir)
        report.generate

        cleanup(worktree)
      end

      private

      def setup_output_dir
        FileUtils.rm_rf(@output_dir)
        FileUtils.mkdir_p(@output_dir)
      end

      def cleanup(worktree)
        worktree.remove
      end
    end
  end
end
