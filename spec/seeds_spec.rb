#require 'spec_helper'
require 'yaml'
require_relative '../lib/rspec_ruby_runner'

$runner = RspecRubyRunner.new

def runs_without_error code, input
  input = input.to_s
  input += "\n" if !input.end_with?("?")
  it 'runs without error' do
    $runner.output_from(code, input)
  end
end
def matches_expected_output code, input, expected_output
  input = input.to_s
  input += "\n" if !input.end_with?("?")
  it 'matches expected_output' do
    begin
      output = $runner.output_from(code, input)
      output.rstrip.should == expected_output.to_s.rstrip
    rescue
      STDERR.puts code
      raise
    end
  end
end

describe 'db/' do
  Dir.glob(File.dirname(__FILE__) + '/../db/*.yaml').sort.each do |path|
    filename = path.split('/').last
    next if filename == '99_advanced.yaml'
    next unless filename.start_with? '0'
    yaml = YAML.load_file(path)

    describe filename do
      %w[purple yellow blue red green].each do |color|
        yaml[color].each_with_index do |exercise, i|
          if %w[purple yellow blue].include?(color)
            code = exercise['code']
          else
            code = exercise['solution']
          end

          if exercise['cases']
            exercise['cases'].each_with_index do |case_, j|
              describe "#{color}[#{i}]'s code case[#{j}]" do
                if %w[blue red green].include? color
                  matches_expected_output code,
                    case_['input'], case_['expected_output']
                else
                  runs_without_error code, case_['input']
                end
              end
            end
          else # no cases
            describe "#{color}[#{i}]'s code" do
              if %w[blue red green].include? color
                raise "Missing cases"
              else
                runs_without_error code, nil
              end
            end
          end # end if cases or not

        end # next exercise
      end # next color
    end # end describe filename

  end # next .yaml
end # end describe db/
