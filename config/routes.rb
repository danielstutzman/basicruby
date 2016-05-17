BasicRuby::Application.routes.draw do


  get  '/api/all_exercises'            => 'api#all_exercises'
  get  '/api/menu'                     => 'api#menu'
  get  '/api/exercise/:path'           => 'api#exercise'
  get  '/api/exercise/:path/:rep_num'  => 'api#exercise'
  post '/api/mark_complete'            => 'api#mark_complete'
end
