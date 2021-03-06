require 'spec_helper'

describe Problem do
  context 'when no test nor expectations' do
    let(:problem) { build(:problem, test: nil, expectations: []) }
    it { expect(problem.evaluation_criteria?).to be false }
  end

  context 'when no test but expectations' do
    let(:problem) { build(:problem, test: nil, expectations: [{inspection: 'HasBinding', binding: 'foo'}]) }
    it { expect(problem.evaluation_criteria?).to be true }
  end

  context 'when no test nor expectations' do
    let(:problem) { build(:problem, test: 'describe ...', expectations: []) }
    it { expect(problem.evaluation_criteria?).to be true }
  end


  context 'when solving then failing' do
    let!(:problem) { create(:problem) }
    let!(:user) { create(:user) }

    before do
      assignment = problem.submit_solution!(user, content: 'foo')

      assignment.test_results = [{title: 'foo', result: '', status: :passed}]
      assignment.expectation_results = [{result: :passed, binding: 'foo', inspection: 'HasBinding'}]
      assignment.status = :passed
      assignment.save!

      @assignment = problem.submit_solution!(user, content: 'bar')
    end

    it { expect(@assignment.expectation_results).to eq [] }
    it { expect(@assignment.test_results).to eq nil }
    it { expect(@assignment.result).to eq 'noop result' }
    it { expect(@assignment.status).to eq Status::Failed }
  end
end
