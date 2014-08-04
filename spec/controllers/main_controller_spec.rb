# see http://guides.rubyonrails.org/testing.html#integration-testing
# http://guides.rubyonrails.org/testing.html#helpers-available-for-integration-tests
# http://rubydoc.info/gems/factory_girl/file/GETTING_STARTED.md

require 'spec_helper'

describe MainController do
  describe '#menu' do

    it "creates a new learner if none in session" do
      Learner.count.should == 0

      get :menu

      Learner.count.should == 1
      assigns(:learner).id.should == 1
    end

    it "uses existing learner if provided in session" do
      learner = create :learner
      Learner.count.should == 1

      get :menu, {}, learner_id: learner.id

      Learner.count.should == 1
      assigns(:learner).id.should == learner.id
    end

  end
end
