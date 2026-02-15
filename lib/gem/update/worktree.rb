# frozen_string_literal: true

require "fileutils"

module Gem
  module Update
    class Worktree
      attr_reader :path

      def initialize(name, base_dir:, suffix: "worktree")
        @name = name
        @path = File.join(base_dir, suffix)
      end

      def create(ref: "HEAD")
        FileUtils.mkdir_p(File.dirname(@path))
        system("git", "worktree", "add", @path, ref, out: File::NULL, err: File::NULL)
      end

      def remove
        system("git", "worktree", "remove", @path, "--force", out: File::NULL, err: File::NULL)
      end
    end
  end
end
