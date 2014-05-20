BasicRuby::Application.routes.draw do
  root 'static#index'

  get '/:topic_num.:level_and_color' => 'machine#exercise'
end
