BasicRuby::Application.routes.draw do
  root 'static#index'

  get '/:path' => 'machine#exercise'
end
