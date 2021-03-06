require 'spec_helper'

describe Exercise do
  let(:exercise) { create(:exercise) }
  let(:user) { create(:user) }

  before { I18n.locale = :en }

  describe '#next_for' do
    context 'when exercise has no guide' do
      it { expect(exercise.next_for(user)).to be nil }
    end
    context 'when exercise belong to a guide with a single exercise' do
      let(:exercise_with_guide) { create(:exercise, guide: guide) }
      let(:guide) { create(:guide) }

      it { expect(exercise_with_guide.next_for(user)).to be nil }
    end
    context 'when exercise belongs to a guide with two exercises' do
      let!(:exercise_with_guide) { create(:exercise, guide: guide, position: 2) }
      let!(:alternative_exercise) { create(:exercise, guide: guide, position: 3) }
      let!(:guide) { create(:guide) }

      it { expect(exercise_with_guide.next_for(user)).to eq alternative_exercise }
    end
    context 'when exercise belongs to a guide with two exercises and alternative exercise has being solved' do
      let(:exercise_with_guide) { create(:exercise, guide: guide) }
      let!(:alternative_exercise) { create(:exercise, guide: guide) }
      let(:guide) { create(:guide) }

      before { alternative_exercise.submit_solution!(user, content: 'foo').passed! }

      it { expect(exercise_with_guide.next_for(user)).to be nil }
    end

    context 'when exercise belongs to a guide with two exercises and alternative exercise has being submitted but not solved' do
      let!(:exercise_with_guide) { create(:exercise, guide: guide, position: 2) }
      let!(:alternative_exercise) { create(:exercise, guide: guide, position: 3) }
      let(:guide) { create(:guide) }

      before { alternative_exercise.submit_solution!(user, content: 'foo') }

      it { expect(guide.exercises.at_locale).to_not eq [] }
      it { expect(guide.pending_exercises(user)).to_not eq [] }
      it { expect(guide.next_exercise(user)).to_not be nil }
      it { expect(guide.pending_exercises(user)).to include(alternative_exercise) }
      it { expect(exercise_with_guide.next_for(user)).to eq alternative_exercise }
      it { expect(guide.exercises).to_not eq [] }
      it { expect(exercise_with_guide.guide).to eq guide }
      it { expect(guide.pending_exercises(user)).to include(exercise_with_guide) }
    end
  end

  describe '#previous_for' do
    context 'when exercise belongs to a guide with two exercises' do
      let!(:exercise_with_guide) { create(:exercise, guide: guide, position: 3) }
      let!(:alternative_exercise) { create(:exercise, guide: guide, position: 2) }
      let!(:guide) { create(:guide) }

      it { expect(exercise_with_guide.previous_for(user)).to eq alternative_exercise }
    end
  end

  describe '#extra_code' do
    context 'when exercise has no extra code' do
      it { expect(exercise.extra_code).to eq '' }
    end

    context 'when exercise has extra code and has no guide' do
      let!(:exercise_with_extra_code) { create(:exercise, extra_code: 'exercise extra code') }

      it { expect(exercise_with_extra_code.extra_code).to eq 'exercise extra code' }
    end

    context 'when exercise has extra code and belong to a guide with no extra code' do
      let!(:exercise_with_extra_code) { create(:exercise, guide: guide, extra_code: 'exercise extra code') }
      let!(:guide) { create(:guide) }

      it { expect(exercise_with_extra_code.extra_code).to eq 'exercise extra code' }
    end

    context 'when exercise has extra code and belong to a guide with extra code' do
      let!(:exercise_with_extra_code) { create(:exercise, guide: guide, extra_code: 'exercise extra code') }
      let!(:guide) { create(:guide, extra_code: 'guide extra code') }

      it { expect(exercise_with_extra_code.extra_code).to eq "guide extra code\nexercise extra code" }
      it { expect(exercise_with_extra_code[:extra_code]).to eq 'exercise extra code' }
    end
  end

  describe '#submitted_by?' do
    context 'when user did a submission' do
      before { exercise.submit_solution!(user) }
      it { expect(exercise.assigned_to? user).to be true }
    end
    context 'when user did no submission' do
      it { expect(exercise.assigned_to? user).to be false }
    end
  end

  describe '#solved_by?' do
    context 'when user did no submission' do
      it { expect(exercise.solved_by? user).to be false }
    end
    context 'when user did a successful submission' do
      before { exercise.submit_solution!(user).passed! }

      it { expect(exercise.solved_by? user).to be true }
    end
    context 'when user did a pending submission' do
      before { exercise.submit_solution!(user) }

      it { expect(exercise.solved_by? user).to be false }
    end
    context 'when user did both successful and failed submissions' do
      before do
        exercise.submit_solution!(user)
        exercise.submit_solution!(user).passed!
      end

      it { expect(exercise.solved_by? user).to be true }
    end
  end

  describe '#destroy' do
    context 'when there are no submissions' do
      it { exercise.destroy! }
    end

    context 'when there are submissions' do
      let!(:assignment) { create(:assignment, exercise: exercise) }
      before { exercise.destroy! }
      it { expect { Assignment.find(assignment.id) }.to raise_error(ActiveRecord::RecordNotFound) }
    end

  end

  describe '#previous_solution_for' do
    context 'when user has a single submission for the exercise' do
      let!(:assignment) { exercise.submit_solution!(user, content: 'foo') }

      it { expect(exercise.previous_solution_for(user)).to eq assignment.solution }
    end

    context 'when user has no submissions for the exercise' do
      it { expect(exercise.previous_solution_for(user)).to eq '' }
    end


    context 'when user has multiple submission for the exercise' do
      let!(:assignments) { [exercise.submit_solution!(user, content: 'foo'),
                            exercise.submit_solution!(user, content: 'bar')] }

      it { expect(exercise.previous_solution_for(user)).to eq assignments.last.solution }
    end
  end

  describe '#by_tag' do
    let!(:tagged_exercise) { create(:exercise, tag_list: 'foo') }
    let!(:untagged_exercise) { create(:exercise) }

    it { expect(Exercise.by_tag('foo')).to include(tagged_exercise) }
    it { expect(Exercise.by_tag('foo')).to_not include(untagged_exercise) }

    it { expect(Exercise.by_tag('bar')).to_not include(tagged_exercise, untagged_exercise) }

    it { expect(Exercise.by_tag(nil)).to include(tagged_exercise, untagged_exercise) }
  end

  describe '#original_id' do
    let(:exercise) { create(:exercise) }
    context 'no original id' do
      it { expect(exercise.original_id).to be nil }
    end
    context 'after generation' do
      before { exercise.generate_original_id! }
      it { expect(exercise.original_id).to eq exercise.id }
    end
    context 'after regeneration' do
      before do
        exercise.update!(original_id: 1)
        exercise.generate_original_id!
      end
      it { expect(exercise.original_id).to eq 1 }
    end
  end

  describe '#authored_by?' do
    let(:other_user) { create(:user) }

    context 'when it does not belong to a guide' do
      it { expect(exercise.authored_by?(exercise.author)).to be true }
      it { expect(exercise.authored_by?(other_user)).to be false }
    end

    context 'when it belongs to a guide' do
      let(:collaborator) { create(:user) }
      let(:guide) { create(:guide, collaborators: [collaborator]) }
      let(:exercise_in_guide) { create(:exercise, guide: guide) }

      it { expect(exercise_in_guide.authored_by?(guide.author)).to be true }
      it { expect(exercise_in_guide.authored_by?(exercise_in_guide.author)).to be true }
      it { expect(exercise_in_guide.authored_by?(collaborator)).to be true }
      it { expect(exercise_in_guide.authored_by?(other_user)).to be false }
    end
  end

  describe '#guide_done_for?' do

    context 'when it does not belong to a guide' do
      it { expect(exercise.guide_done_for?(user)).to be false }
    end

    context 'when it belongs to a guide unfinished' do
      let!(:guide) { create(:guide) }
      let!(:exercise_unfinished) { create(:exercise, guide: guide) }
      let!(:exercise_finished) { create(:exercise, guide: guide) }

      before do
        exercise_finished.submit_solution!(user, content: 'foo').passed!
      end

      it { expect(exercise_finished.guide_done_for?(user)).to be false }
    end

    context 'when it belongs to a guide unfinished' do
      let!(:guide) { create(:guide) }
      let!(:exercise_finished) { create(:exercise, guide: guide) }
      let!(:exercise_finished2) { create(:exercise, guide: guide) }

      before do
        exercise_finished.submit_solution!(user, content: 'foo').passed!
        exercise_finished2.submit_solution!(user, content: 'foo').passed!
      end

      it { expect(exercise_finished.guide_done_for?(user)).to be true }
    end
  end

  describe '#language' do
    let(:guide) { create(:guide) }
    let(:exercise_with_guide) { create(:exercise, guide: guide, language: guide.language) }
    let(:other_language) { create(:language) }

    context 'when has no guide' do
      it { expect(exercise.valid?).to be true }
    end

    context 'when has guide and is consistent' do
      it { expect(exercise_with_guide.valid?).to be true }
    end

    context 'when has guide and is not consistent' do
      before { exercise_with_guide.language = other_language }
      it { expect(exercise_with_guide.valid?).to be false }
    end
  end

  describe '#slug' do
    it { expect(Exercise.find(exercise.slug)).to eq exercise }
    it { expect(Problem.find(exercise.slug)).to eq exercise }
  end
end
