json.learner_id session[:learner_id]
json.topics do
  json.array! @topics do |topic|
    json.num               topic.num
    json.nickname          topic.nickname
    json.under_contruction topic.under_construction
    json.title             topic.title
    json.title_html        topic.title_html
    json.num_completed do
      %w[purple yellow blue red green].each do |color|
        key = [topic.id, color]
        if @topic_id_color_next_path[key]
          json.set! color, (@topic_id_color_num_completions[key] || {}).size
        end
      end
    end
  end
end
