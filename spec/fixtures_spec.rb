#require 'spec_helper'
require 'yaml'
require_relative '../lib/rspec_ruby_runner'

$runner = RspecRubyRunner.new

def runs_without_error code
  it 'runs without error' do
    if !code.include?('gets')
      $runner.output_from(code)
    end
  end
end
def matches_expected_output code, expected_output
  it 'matches expected_output' do
    begin
      if !code.include?('gets')
        output = $runner.output_from(code)
        output.rstrip.should == expected_output.to_s.rstrip
      end
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
    yaml = YAML.load_file(path)

    describe filename do
      #%w[purple yellow red blue green].each do |color|
      #  describe color do
      #    yaml[color]
      #  end
      #end
      yaml['yellow'].each_with_index do |exercise, i|
        describe "yellow[#{i}]'s code" do
          runs_without_error exercise['code']
        end
      end

      yaml['blue'].each_with_index do |exercise, i|
        describe "blue[#{i}]'s code" do
          matches_expected_output exercise['code'],
            exercise['cases'][0]['expected_output']
        end
      end

      yaml['red'].each_with_index do |exercise, i|
        describe "red[#{i}]'s solution" do
          matches_expected_output exercise['solution'],
            exercise['cases'][0]['expected_output']
        end
      end

      yaml['green'].each_with_index do |exercise, i|
        describe "green[#{i}]'s solution" do
          matches_expected_output exercise['solution'],
            exercise['cases'][0]['expected_output']
        end
      end

    end
  end
end
