RSpec.describe TFStateNamespaceLister do
  let(:bucket_contents) { double(:bucket_contents, contents: contents) }

  let(:io) { double(:io, read: state) }
  let(:s3obj) { double(:s3obj, body: double(:io, read: '{ "modules": [] }')) }
  let(:s3client) { double(:s3client, list_objects: bucket_contents, get_object: s3obj) }

  let(:bucket_prefix) { 'qqq' }
  let(:tfstate_class) { TFStateNamespaceLister::TFState }

  let(:params) { {
    bucket: double(:bucket),
    bucket_prefix: bucket_prefix,
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
    let(:s3obj) { double(:s3obj, key: 'qqq/money-to-prisoners-prod/terraform.tfstate', body: io) }
    let(:contents) { [s3obj] }

    let(:resources) { [
      { type: 'aws_ecr_lifecycle_policy', id: 'prisoner-money/money-to-prisoners' },
      { type: 'aws_ecr_repository', id: 'prisoner-money/money-to-prisoners' },
      { type: 'aws_iam_user', id: 'ecr-user-3071a3145d675234' },
      { type: 'aws_iam_user_policy', id: 'ecr-user-3071a3145d675234:ecr-read-write' },
    ] }

    let(:tfstate) {
      tfstate_class.new('money-to-prisoners-prod', resources)
    }

    it "lists AWS resources in namespace" do
      expected = [tfstate]
      expect(lister.namespaces).to eq(expected)
    end
  end

  context "given a list of s3 bucket objects" do
    let(:obj1) { double(:s3obj, key: key1) }
    let(:obj2) { double(:s3obj, key: key2) }
    let(:obj3) { double(:s3obj, key: key3) }

    let(:contents) { [obj1, obj2, obj3] }

    let(:namespaces) { [
      tfstate_class.new('weekly-app-deploy-oa',  []),
      tfstate_class.new('whereabouts-dev',       []),
      tfstate_class.new('vv-myapp-dev',          []),
    ] }

    context "in live0" do
      let(:bucket_prefix) { 'cloud-platform-live-0.k8s.integration.dsd.io/' }

      let(:key1) { "cloud-platform-live-0.k8s.integration.dsd.io/weekly-app-deploy-oa/terraform.tfstate" }
      let(:key2) { "cloud-platform-live-0.k8s.integration.dsd.io/whereabouts-dev/terraform.tfstate" }
      let(:key3) { "cloud-platform-live-0.k8s.integration.dsd.io/vv-myapp-dev/terraform.tfstate" }


      it "extracts namespace names" do
        expect(lister.namespaces).to eq(namespaces)
      end
    end

    context "in live1" do
      let(:bucket_prefix) { '' }

      let(:key1) { "weekly-app-deploy-oa/terraform.tfstate" }
      let(:key2) { "whereabouts-dev/terraform.tfstate" }
      let(:key3) { "vv-myapp-dev/terraform.tfstate" }

      it "extracts namespace names" do
        expect(lister.namespaces).to eq(namespaces)
      end
    end
  end
end
