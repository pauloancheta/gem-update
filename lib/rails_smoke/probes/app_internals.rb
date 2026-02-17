# frozen_string_literal: true

# Probe script: app_internals
#
# Boots the Rails application, then discovers job classes and mailer classes.
# Writes probe_jobs.txt and probe_mailers.txt to output_dir.
#
# Usage: bundle exec ruby app_internals.rb <config_path>
# The config YAML must contain "output_dir".
#
# This script is self-contained — it does NOT require "rails_smoke".

require "yaml"

config = YAML.safe_load_file(ARGV[0])
output_dir = config.fetch("output_dir")

# --- Boot Rails ---

boot_ok = true

begin
  require File.expand_path("config/environment")
rescue => e # rubocop:disable Style/RescueStandardError
  boot_ok = false
  boot_error = "#{e.class}: #{e.message}"
end

unless boot_ok
  File.write(File.join(output_dir, "probe_jobs.txt"), "status: SKIPPED\nreason: boot failed (#{boot_error})\n")
  File.write(File.join(output_dir, "probe_mailers.txt"), "status: SKIPPED\nreason: boot failed (#{boot_error})\n")
  exit 0
end

# --- Jobs ---

jobs_output = +""

if defined?(ActiveJob::Base)
  Rails.application.eager_load! unless Rails.application.config.eager_load

  jobs = ActiveJob::Base.descendants.filter_map do |klass|
    name = klass.name
    next if name.nil? || name.match?(/\A#</)

    queue = klass.queue_name || "default"
    [name, queue]
  end.sort_by(&:first)

  jobs_output << "status: OK\n"
  jobs_output << "jobs:\n"
  jobs.each { |name, queue| jobs_output << "  #{name} (queue: #{queue})\n" }
else
  jobs_output << "status: SKIPPED\nreason: ActiveJob not loaded\n"
end

File.write(File.join(output_dir, "probe_jobs.txt"), jobs_output)

# --- Mailers ---

mailers_output = +""

if defined?(ActionMailer::Base)
  Rails.application.eager_load! unless Rails.application.config.eager_load

  mailers = ActionMailer::Base.descendants.filter_map do |klass|
    name = klass.name
    next if name.nil? || name.match?(/\A#</)

    actions = (klass.public_instance_methods(false) - ActionMailer::Base.public_instance_methods(false)).sort
    [name, actions]
  end.sort_by(&:first)

  mailers_output << "status: OK\n"
  mailers_output << "mailers:\n"
  mailers.each do |name, actions|
    mailers_output << "  #{name}\n"
    mailers_output << "    actions: #{actions.join(", ")}\n" unless actions.empty?
  end
else
  mailers_output << "status: SKIPPED\nreason: ActionMailer not loaded\n"
end

File.write(File.join(output_dir, "probe_mailers.txt"), mailers_output)

exit 0
