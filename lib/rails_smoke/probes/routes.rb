# frozen_string_literal: true

# Probe script: routes
#
# Runs `bundle exec rails routes` and writes the route table to probe_routes.txt.
#
# Usage: bundle exec ruby routes.rb <config_path>
# The config YAML must contain "output_dir".
#
# This script is self-contained — it does NOT require "rails_smoke".

require "yaml"
require "open3"

config = YAML.safe_load_file(ARGV[0])
output_dir = config.fetch("output_dir")

stdout, stderr, status = Open3.capture3("bundle", "exec", "rails", "routes")

output = +""

if status.success?
  output << "status: OK\n"
  output << "routes:\n"
  stdout.each_line do |line|
    route = line.rstrip
    output << "  #{route}\n" unless route.strip.empty?
  end
else
  output << "status: FAILED\n"
  output << "error:\n#{stderr}\n"
end

File.write(File.join(output_dir, "probe_routes.txt"), output)

exit 0
