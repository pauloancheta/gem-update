# frozen_string_literal: true

# Probe script: rake_tasks
#
# Runs `bundle exec rails -T` and writes the task list to probe_rake_tasks.txt.
#
# Usage: bundle exec ruby rake_tasks.rb <config_path>
# The config YAML must contain "output_dir".
#
# This script is self-contained — it does NOT require "rails_smoke".

require "yaml"
require "open3"

config = YAML.safe_load_file(ARGV[0])
output_dir = config.fetch("output_dir")

stdout, stderr, status = Open3.capture3("bundle", "exec", "rails", "-T")

output = +""

if status.success?
  output << "status: OK\n"
  output << "tasks:\n"
  stdout.each_line do |line|
    task = line.strip
    output << "  #{task}\n" unless task.empty?
  end
else
  output << "status: FAILED\n"
  output << "error:\n#{stderr}\n"
end

File.write(File.join(output_dir, "probe_rake_tasks.txt"), output)

exit 0
