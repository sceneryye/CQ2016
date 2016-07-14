require 'test_helper'

class Events::ApplicantsControllerTest < ActionController::TestCase
  
  test "should create applicant" do
    assert_difference('Applicant.count') do
    	xhr :post, :create, :applicant=>
    end

    assert_response :success
  end


end
