BasicRuby::Application.routes.draw do
  root 'main#menu'

  get '/:path' => 'main#exercise'
end
