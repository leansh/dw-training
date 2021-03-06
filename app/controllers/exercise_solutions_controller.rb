class ExerciseSolutionsController < ApplicationController
  include NestedInExercise

  before_action :authenticate!
  before_action :set_guide_previously_done

  def create
    assignment = @exercise.submit_solution!(current_user, solution_params)

    render partial: 'exercise_solutions/results',
           locals: {assignment: assignment,
                    guide_finished_by_solution: guide_finished_by_solution?}
  end

  private

  def guide_finished_by_solution?
    !@guide_previously_done && @exercise.guide_done_for?(current_user)
  end

  def set_guide_previously_done
    @guide_previously_done = @exercise.guide_done_for?(current_user)
  end

  def solution_params
    params.require(:solution).permit(:content)
  end
end
