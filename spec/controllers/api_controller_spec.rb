require 'spec_helper'

describe ApiController do
  describe 'GET #menu' do
    it "returns the information for one test_model" do
      learner = create(:learner)
      get :menu, {format: :json}, {learner_id: learner.id}
      JSON.parse(response.body) == { 'learner_id'=>1, 'topics'=>[] }
    end
  end
end
