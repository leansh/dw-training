require 'spec_helper'

describe Event do

  describe '#to_job_params!' do
    let(:subscriber) { EventSubscriber.create!(id: 2, enabled: true, url: 'http://localhost:80') }
    let(:user) { create(:user) }
    let(:job_params) { event.to_job_params(subscriber) }

    describe Event::Registration do
      let(:event) { Event::Registration.new(user) }

      it { expect(job_params.subscriber_id).to eq 2 }
      it { expect(job_params.event_json).to_not include 'token' }
      it { expect(job_params.event_path).to eq 'events/registration' }
    end

    describe Event::Submission do
      let(:assignment) { create(:exercise).submit_solution!(user) }

      let(:event) { Event::Submission.new(assignment) }

      it { expect(job_params.subscriber_id).to eq 2 }
      it { expect(job_params.event_json).to include '"status":"failed"' }
      it { expect(job_params.event_path).to eq 'events/submissions' }
    end

  end

  describe '#to_json' do

    describe Event::Submission do
      let(:user) { create(:user, id: 2, name: 'foo') }
      let(:assignment) { create(:assignment,
                                solution: 'x = 2',
                                status: Status::Passed,
                                submissions_count: 2,
                                submitter: user,
                                submission_id: 'abcd1234') }
      let(:event) { Event::Submission.new(assignment) }

      it { expect(event.as_json).to eq({'status' => Status::Passed,
                                        'result' => nil,
                                        'expectation_results' => nil,
                                        'feedback' => nil,
                                        'test_results' => nil,
                                        'submissions_count' => 2,
                                        'exercise' => {'id' => assignment.exercise.id, 'guide_id' => nil},
                                        'submitter' => {'id' => 2, 'name' => 'foo'},
                                        'id' => 'abcd1234',
                                        'created_at' => assignment.updated_at,
                                        'content' => 'x = 2'
                                       }) }
    end
  end


end
