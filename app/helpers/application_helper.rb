module ApplicationHelper
  def image_tag_for_exercise exercise, size
    image_tag_for_exercise_color exercise.color, size
  end
  def image_tag_for_exercise_color color, size
    case color
    when 'yellow'
      image_tag 'exercise_icons/light_bulb30.png',
        width: size, height: size
    when 'red'
      image_tag 'exercise_icons/red_bug30.png',
        width: size, height: size
    when 'blue'
      image_tag 'exercise_icons/question_mark30.png',
        width: size, height: size
    when 'green'
      image_tag 'exercise_icons/pen-and-paper-60.png',
        width: size, height: size
    when 'orange'
      image_tag 'exercise_icons/jack-o-lantern-60.png',
        width: size, height: size
    end
  end
end
