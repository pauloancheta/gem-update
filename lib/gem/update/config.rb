# frozen_string_literal: true

require "yaml"

module Gem
  module Update
    class Config
      DEFAULTS = {
        "server" => false,
        "before_port" => 3000,
        "after_port" => 3001,
        "rails_env" => "test",
        "sandbox" => true,
        "setup_task" => nil,
        "setup_script" => nil,
        "database_url_base" => nil
      }.freeze

      def initialize(project_root: Dir.pwd)
        @settings = load_settings(project_root)
      end

      def gem_name
        @settings["gem_name"]
      end

      def server?
        @settings["server"]
      end

      def before_port
        @settings["before_port"]
      end

      def after_port
        @settings["after_port"]
      end

      def version
        @settings["version"]
      end

      def rails_env
        @settings["rails_env"]
      end

      def sandbox?
        @settings["sandbox"]
      end

      def setup_task
        @settings["setup_task"]
      end

      def setup_script
        @settings["setup_script"]
      end

      def database_url_base
        @settings["database_url_base"]
      end

      private

      def load_settings(project_root)
        path = File.join(project_root, ".gem_update.yml")

        unless File.exist?(path)
          raise Gem::Update::Error, "Config file not found: .gem_update.yml\nRun `gem-update init` to create one."
        end

        yaml = YAML.safe_load_file(path) || {}
        settings = DEFAULTS.merge(yaml)

        gem_name = settings["gem_name"]
        if gem_name.nil? || (gem_name.is_a?(String) && gem_name.strip.empty?)
          raise Gem::Update::Error, "gem_name is required in .gem_update.yml"
        end

        settings
      end
    end
  end
end
