BasicRuby::Application.routes.draw do
  root 'static#index'

  get '/1' => 'curriculum#unit_1'
  get '/2' => 'curriculum#unit_2'

  get '/:unit_num.:lesson_num.:exercise_num' => 'machine#exercise'

end
