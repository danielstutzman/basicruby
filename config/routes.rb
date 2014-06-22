BasicRuby::Application.routes.draw do
  root 'main#menu'

  # make sure this comes before more general routes
  get '/yt/:youtube_id' => 'main#landing_page'

  get '/:path'          => 'main#exercise'
  get '/:path/:rep_num' => 'main#exercise'

  post '/post/mark_complete' => 'main#mark_complete'
end
