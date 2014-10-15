BasicRuby::Application.routes.draw do
  match '*path', controller: 'application', action: 'options_for_cors',
    via: 'options'

  root 'main#menu'

  # make sure these routes come before more general routes
  get  '/tutor'                   => 'tutor#welcome'
  get  '/tutor/exercise/:task_id' => 'tutor#exercise'
  post '/tutor/exercise/:task_id' => 'tutor#post_to_database'
  get  '/yt/:youtube_id'          => 'main#landing_page'

  get  '/easyxdm.html'                 => 'api#easyxdm'
  get  '/api/all_exercises'            => 'api#all_exercises'
  get  '/api/menu'                     => 'api#menu'
  get  '/api/exercise/:path'           => 'api#exercise'
  get  '/api/exercise/:path/:rep_num'  => 'api#exercise'
  post '/api/mark_complete'            => 'api#mark_complete'
  get  '/api/tutor'                    => 'tutor#api_welcome'
  get  '/api/tutor/exercise/:task_id'  => 'tutor#api_exercise'
  post '/api/tutor/save_tutor_code'    => 'tutor#api_save_tutor_code'
  post '/api/tutor/discard_tutor_code' => 'tutor#api_discard_tutor_code'

  get  '/:path'          => 'main#exercise'
  get  '/:path/:rep_num' => 'main#exercise'

  post '/post/mark_complete' => 'main#mark_complete'
end
