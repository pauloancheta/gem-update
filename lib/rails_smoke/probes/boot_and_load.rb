# frozen_string_literal: true

# Probe script: boot_and_load
#
# Boots the Rails application, then attempts eager loading.
# Writes probe_boot.txt and probe_eager_load.txt to output_dir.
#
# Usage: bundle exec ruby boot_and_load.rb <config_path>
# The config YAML must contain "output_dir".
#
# This script is self-contained — it does NOT require "rails_smoke".

require "yaml"

config = YAML.safe_load_file(ARGV[0])
output_dir = config.fetch("output_dir")

# --- Boot check ---

boot_status = "OK"
boot_error = nil
boot_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

begin
  require File.expand_path("config/environment")
rescue => e # rubocop:disable Style/RescueStandardError
  boot_status = "FAILED"
  boot_error = "#{e.class}: #{e.message}\n#{e.backtrace&.first(20)&.join("\n")}"
end

boot_elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - boot_start

boot_output = +"status: #{boot_status}\n"
boot_output << "error:\n#{boot_error}\n" if boot_error

File.write(File.join(output_dir, "probe_boot.txt"), boot_output)

# --- Eager load check ---

if boot_status == "FAILED"
  File.write(File.join(output_dir, "probe_eager_load.txt"), "status: SKIPPED\nreason: boot failed\n")
  exit 0
end

eager_status = "OK"
eager_error = nil

begin
  Rails.application.eager_load!

  constants = ObjectSpace.each_object(Module).filter_map do |mod|
    name = mod.name
    next if name.nil?
    next if name.match?(/\A#</) # skip anonymous classes/modules

    name
  end.sort.uniq

  eager_output = +"status: #{eager_status}\n"
  eager_output << "constants_count: #{constants.size}\n"
  eager_output << "constants:\n"
  constants.each { |c| eager_output << "  #{c}\n" }
rescue => e # rubocop:disable Style/RescueStandardError
  eager_status = "FAILED"
  eager_error = "#{e.class}: #{e.message}\n#{e.backtrace&.first(20)&.join("\n")}"

  eager_output = +"status: #{eager_status}\n"
  eager_output << "error:\n#{eager_error}\n"
end

File.write(File.join(output_dir, "probe_eager_load.txt"), eager_output)

exit 0
