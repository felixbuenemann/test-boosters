require 'rspec/core/version'

module TestBoosters
  module Boosters
    class Rspec < Base
      def initialize
        super(file_pattern, exclude_pattern, split_configuration_path, command)
      end

      def display_header
        super

        TestBoosters::ProjectInfo.display_ruby_version
        TestBoosters::ProjectInfo.display_bundler_version
        TestBoosters::ProjectInfo.display_rspec_version
      end

      def after_job
        TestBoosters::InsightsUploader.upload("rspec", report_path)
      end

      def command
        @command ||= "bundle exec rspec #{rspec_options}"
      end

      def rspec_options
        @rspec_options ||= begin
          output_formatter = ENV.fetch("TB_RSPEC_FORMATTER", "documentation")
          if ENV["TB_RSPEC_DISABLE_SEMAPHORE_REPORT"]
            "#{ENV["TB_RSPEC_OPTIONS"]} --format #{output_formatter}"
          else
            # rubocop:disable LineLength
            "#{ENV["TB_RSPEC_OPTIONS"]} --format #{output_formatter} --require #{formatter_path} --format SemaphoreFormatter --out #{report_path}"
          end
        end
      end

      def report_path
        @report_path ||= ENV["REPORT_PATH"] || "#{ENV["HOME"]}/rspec_report.json"
      end

      def split_configuration_path
        ENV["RSPEC_SPLIT_CONFIGURATION_PATH"] || "#{ENV["HOME"]}/rspec_split_configuration.json"
      end

      def formatter_path
        @formatter_path ||= File.join(::TestBoosters::ROOT_PATH, "rspec_formatters/semaphore_rspec#{rspec_version}_json_formatter.rb")
      end

      def file_pattern
        ENV["TEST_BOOSTERS_RSPEC_TEST_FILE_PATTERN"] || "spec/**/*_spec.rb"
      end

      def exclude_pattern
        ENV["TEST_BOOSTERS_RSPEC_TEST_EXCLUDE_PATTERN"]
      end

      private

      def rspec_version
        @rspec_version ||= ::RSpec::Core::Version::STRING.start_with?("2.") ? 2 : 3
      end
    end
  end
end
