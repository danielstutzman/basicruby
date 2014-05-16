require 'yaml'

class Exercise < ActiveRecord::Base
  def yaml_loaded
    @yaml_loaded ||= YAML.load self.yaml
  end
end
