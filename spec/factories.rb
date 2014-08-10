FactoryGirl.define do

  factory :learner do
  end

  factory :topic do
    num 1
    sequence(:nickname) { |n| "nickname#{n}" }
    sequence(:title)    { |n| "title#{n}" }
    level 'beginner'
    features ''
    under_construction false
  end

  factory :exercise do
    topic
    topic_num 1
    color :purple
    json '{}'
  end

end
