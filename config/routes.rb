BasicRuby::Application.routes.draw do
  root 'static#index'

  get '/1' => 'curriculum#unit_1'
  get '/2' => 'curriculum#unit_2'

  get '/1.1.1' => 'machine#_1_1_1'
  get '/1.1.2' => 'machine#_1_1_2'

end
