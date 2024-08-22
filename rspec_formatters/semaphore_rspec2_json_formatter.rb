require 'rspec/core/formatters/base_formatter'
require 'json'

puts "Semaphore Formatter for RSpec 2.x loaded"

class SemaphoreFormatter < RSpec::Core::Formatters::BaseFormatter
  def initialize(output)
    super(output)
    @output_hash = {}
  end

  # This method is called when the entire suite has finished running
  def dump_summary(duration, example_count, failure_count, pending_count)
    examples = RSpec.world.example_groups.map(&:examples).flatten
    @output_hash[:examples] = examples.map { |example| format_example(example) }
  end

  # This method is called at the very end of the suite
  def close
    output.write @output_hash.to_json
    output.close if IO === output && output != $stdout
  end

  private

  def format_example(example)
    result = example.execution_result

    {
      :description => example.description,
      :full_description => example.full_description,
      :status => result[:status],
      :file_path => file_path(example),
      :run_time => result[:run_time]
    }
  end

  def file_path(example)
    # For shared examples 'example.file_path' returns the path of the shared example file.
    # This is not optional for our use case because we can't estimate the duration of the
    # original spec file.
    #
    # To resolve this, we use `example.metadata[:example_group]` that contains the correct
    # file path for both shared examples and regular tests

    find_example_group_root_path(example.metadata[:example_group])
  end

  def find_example_group_root_path(example_group)
    if example_group.has_key?(:parent_example_group)
      find_example_group_root_path(example_group[:parent_example_group])
    else
      example_group[:file_path]
    end
  end
end
