json.learner_id session[:learner_id]
json.topics do
  json.array! @topics do |topic|
    json.num               topic.num
    json.nickname          topic.nickname
    json.under_contruction topic.under_construction
    json.title             topic.title
    json.title_html        topic.title_html
    json.level             topic.level
    json.completed do
      %w[purple yellow blue red green].each do |color|
        key = [topic.id, color]
        if @topic_id_color_next_path[key]
          num = (@topic_id_color_num_completions[key] || {}).size
          next_path = @topic_id_color_next_path[key]
          json.set! color, { num: num, next: next_path }
        end
      end
    end
  end
end
