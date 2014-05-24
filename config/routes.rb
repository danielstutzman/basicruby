BasicRuby::Application.routes.draw do
  root 'main#menu'

  get '/:path'          => 'main#exercise'
  get '/:path/:rep_num' => 'main#exercise'
end
