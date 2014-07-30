class TutorExercise < ActiveRecord::Base
  # this method exists so we can whitelist it with Brakeman
  def yaml_loaded
    YAML.load(self.yaml)
  end
end
