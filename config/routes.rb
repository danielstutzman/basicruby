BasicRuby::Application.routes.draw do
  match '*path', controller: 'application', action: 'options_for_cors',
    via: 'options'

  root 'api#root'

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
end
