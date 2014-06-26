SAMPLE_CODE =
"def binary_search(haystack, needle)
  mid = haystack.size / 2
  if needle < haystack[mid]
    __return__ = binary_search(haystack[0..(mid - 1)], needle)
  elsif needle > haystack[mid]
    __return__ = (mid + 1) + binary_search(haystack[(mid + 1)..-1], needle)
  else
    __return__ = mid
  end
end
puts binary_search([4, 9, 12, 13, 17, 18], 17)
"

class TutorController < ApplicationController
  def welcome
    @exercise_group1 = TutorExerciseGroup.find(1)
    @exercise_group2 = TutorExerciseGroup.find(2)
    @other_exercise_groups =
      TutorExerciseGroup.order(:id).to_a.reject { |group| group.id < 3 }
  end
  def exercise
    current_user = Learner.find_by(id: session[:user_id])
    if current_user.nil?
      current_user = Learner.create!
      session[:user_id] = current_user.id
    end

    task_id = params[:task_id]
    exercise = TutorExercise.find_by_task_id(task_id)
    halt(404, 'Exercise not found') if exercise.nil?
    halt(404, 'No code for that exercise') if exercise.yaml.nil?
    begin
      @exercise = YAML.load(exercise.yaml)
    rescue Psych::SyntaxError => e
      halt 500, "#{e.class}: #{e} with #{exercise.yaml}"
    end

    if request.get?
      old_record =
        TutorSave.where({
          :user_id     => current_user.id,
          :task_id     => task_id,
          :is_current  => true
        }).first
      if old_record
        @user_code = old_record.code
      else
        @user_code = @exercise['starting_code'] || ''
      end
    elsif request.post?
      if params['action'] == 'save'
        @user_code = params['user_code_textarea']
        TutorSave.transaction do
          TutorSave.where("is_current = 'f'").update_all({
            :user_id      => current_user.id,
            :task_id      => task_id,
            :is_current   => true
          })
          TutorSave.create({
            :user_id      => current_user.id,
            :task_id      => task_id,
            :is_current   => true,
            :code         => @user_code,
          })
        end
      elsif params['action'] == 'restore'
        TutorSave.where({
          :user_id      => current_user.id,
          :task_id      => task_id,
          :is_current   => true
        }).update_all(:is_current => false)
        redirect "/tutor/exercise/#{task_id}"
      end
    end

    cases_given =
      (@exercise['cases'] || [{}]).map { |_case| _case['given'] || {} }
    #@traces = get_trace_for_cases('', @user_code, cases_given)
@traces = JSON.parse("[{\"code\":\"puts 1\",\"trace\":[{\"ordered_globals\":[],\"stdout\":\"\",\"func_name\":\"main\",\"stack_to_render\":[{\"frame_id\":0,\"encoded_locals\":{},\"is_highlighted\":false,\"is_parent\":false,\"func_name\":\"<main>\",\"is_zombie\":false,\"parent_frame_id_list\":[],\"unique_hash\":\"0_\",\"ordered_varnames\":[]}],\"globals\":{},\"heap\":{},\"line\":1,\"event\":\"step_line\"},{\"ordered_globals\":[],\"stdout\":\"1\\n\",\"func_name\":\"main\",\"stack_to_render\":[{\"frame_id\":0,\"encoded_locals\":{},\"is_highlighted\":false,\"is_parent\":false,\"func_name\":\"<main>\",\"is_zombie\":false,\"parent_frame_id_list\":[],\"unique_hash\":\"0_\",\"ordered_varnames\":[]}],\"globals\":{},\"heap\":{},\"line\":1,\"event\":\"step_line\"}],\"returned\":null}]")

    num_passed = 0
    num_failed = 0
    @traces.each_with_index do |trace, i|
      last = trace['trace'].last || {}
      if last['exception_msg']
        trace['test_status'] = 'ERROR'
      elsif @exercise['cases'].nil? || @exercise['cases'][i].nil?
        # cases don't apply to this exercise
      elsif expected_return = @exercise['cases'][i]['expected_return']
        trace['test_status'] =
          (trace['returned'] == expected_return) ? 'PASSED' : 'FAILED'
      elsif expected_stdout = @exercise['cases'][i]['expected_stdout']
        trace['test_status'] =
          ((last['stdout'] || '').chomp == expected_stdout.chomp) ?
          'PASSED' : 'FAILED'
      end
      num_passed += 1 if trace['test_status'] == 'PASSED'
      num_failed += 1 if trace['test_status'] == 'FAILED' ||
                         trace['test_status'] == 'ERROR'
    end
  end
end
