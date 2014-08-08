BasicRuby::Application.routes.draw do
  root 'main#menu'

  # make sure these routes come before more general routes
  get  '/tutor'                   => 'tutor#welcome'
  get  '/tutor/exercise/:task_id' => 'tutor#exercise'
  post '/tutor/exercise/:task_id' => 'tutor#post_to_database'
  get  '/yt/:youtube_id'          => 'main#landing_page'
  get  '/api/menu'                => 'api#menu'
  match '*path', to: 'api#options', via: :options # for CORS

  get  '/:path'          => 'main#exercise'
  get  '/:path/:rep_num' => 'main#exercise'

  post '/post/mark_complete' => 'main#mark_complete'
end
