# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class RailsSmoke::TestWorktree < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir("rails-smoke-test")
    Dir.chdir(@tmpdir)
    system("git", "init", out: File::NULL, err: File::NULL)
    system("git", "config", "user.email", "test@test.com", out: File::NULL, err: File::NULL)
    system("git", "config", "user.name", "Test", out: File::NULL, err: File::NULL)
    File.write("dummy.txt", "hello")
    system("git", "add", ".", out: File::NULL, err: File::NULL)
    system("git", "commit", "-m", "init", out: File::NULL, err: File::NULL)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_create_and_remove_worktree
    base_dir = File.join(@tmpdir, "output")
    worktree = RailsSmoke::Worktree.new("test-gem", base_dir: base_dir)

    worktree.create
    assert File.directory?(worktree.path)
    assert File.exist?(File.join(worktree.path, "dummy.txt"))

    worktree.remove
    refute File.directory?(worktree.path)
  end

  def test_path
    worktree = RailsSmoke::Worktree.new("rails", base_dir: "/tmp/rails_smoke/rails")
    assert_equal "/tmp/rails_smoke/rails/worktree", worktree.path
  end

  def test_create_with_ref
    # Create a branch with different content
    system("git", "checkout", "-b", "test-branch", out: File::NULL, err: File::NULL)
    File.write("branch_file.txt", "branch content")
    system("git", "add", ".", out: File::NULL, err: File::NULL)
    system("git", "commit", "-m", "branch commit", out: File::NULL, err: File::NULL)
    system("git", "checkout", "-", out: File::NULL, err: File::NULL)

    base_dir = File.join(@tmpdir, "output")
    worktree = RailsSmoke::Worktree.new("test-gem", base_dir: base_dir)

    worktree.create(ref: "test-branch")
    assert File.directory?(worktree.path)
    assert File.exist?(File.join(worktree.path, "branch_file.txt"))

    worktree.remove
  end

  def test_custom_suffix
    base_dir = File.join(@tmpdir, "output")
    worktree = RailsSmoke::Worktree.new("test-gem", base_dir: base_dir, suffix: "before_worktree")

    assert_equal File.join(base_dir, "before_worktree"), worktree.path
    worktree.create
    assert File.directory?(worktree.path)

    worktree.remove
  end
end
