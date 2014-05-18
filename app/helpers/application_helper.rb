module ApplicationHelper
  def image_tag_for_exercise exercise
    image_tag_for_exercise_color exercise.color
  end
  def image_tag_for_exercise_color color
    case color
    when 'gold'
      image_tag 'exercise_icons/light_bulb30.png', width: 60, height: 60
    when 'red'
      image_tag 'exercise_icons/red_bug30.png', width: 60, height: 60
    when 'blue'
      image_tag 'exercise_icons/question_mark30.png', width: 60, height: 60
    when 'green'
      image_tag 'exercise_icons/pen-and-paper-60.png', width: 60, height: 60
    when 'orange'
      image_tag 'exercise_icons/jack-o-lantern-60.png', width: 60, height: 60
    end
  end
end
