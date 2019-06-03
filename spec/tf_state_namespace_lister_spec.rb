RSpec.describe TFStateNamespaceLister do
  let(:bucket_contents) { double(:bucket_contents, contents: contents) }
  let(:s3client) { double(:s3client, list_objects: bucket_contents) }

  let(:params) { {
    bucket: double(:bucket),
    bucket_prefix: 'qqq',
    s3client: s3client,
  } }

  subject(:lister) { described_class.new(params) }

  context "when there are no objects in the bucket" do
    let(:contents) { [] }

    it "returns an empty list" do
      expected = []
      expect(lister.namespaces).to eq(expected)
    end
  end

  context "when there is a single namespace" do
    file = "#{File.dirname(__FILE__)}/fixtures/terraform.tfstate"
    let(:state) { File.read(file) }
    let(:io) { double(:io, read: state) }
    let(:s3obj) { double(:s3obj, key: 'qqq/money-to-prisoners-prod/terraform.tfstate', body: io) }
    let(:s3client) { double(:s3client, list_objects: bucket_contents, get_object: s3obj) }
    let(:contents) { [s3obj] }

    let(:resources) { [
      { type: 'aws_ecr_lifecycle_policy', id: 'prisoner-money/money-to-prisoners' },
      { type: 'aws_ecr_repository', id: 'prisoner-money/money-to-prisoners' },
      { type: 'aws_iam_user', id: 'ecr-user-3071a3145d675234' },
      { type: 'aws_iam_user_policy', id: 'ecr-user-3071a3145d675234:ecr-read-write' },
    ] }
    let(:tfstate) {
      TFStateNamespaceLister::TFState.new('money-to-prisoners-prod', resources)
    }

    it "lists AWS resources in namespace" do
      expected = [tfstate]
      expect(lister.namespaces).to eq(expected)
    end
  end
end
