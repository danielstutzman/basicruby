require 'spec_helper'

describe ApiController do
  describe 'GET #menu' do
    it "returns the information for one test_model" do
      learner = create :learner
      topic = create :topic
      exercise = create :exercise

      get :menu, {format: :json}, {learner_id: learner.id}

      expect_json learner_id: 1, topics: [
        {
          num:         1,
          nickname:   'nickname1',
          title:      'title1',
          title_html: 'title1',
          level:      'beginner',
          under_construction: false,
          completed: {},
        }, {
          num:         1,
          nickname:   'nickname2',
          title:      'title2',
          title_html: 'title2',
          level:      'beginner',
          under_construction: false,
          completed: {
            purple: {
              num: 0,
              next: '/1P',
            },
          },
        }
      ]
    end
  end
end
