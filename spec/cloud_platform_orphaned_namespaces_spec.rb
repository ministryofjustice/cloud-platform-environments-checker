RSpec.describe CloudPlatformOrphanNamespaces do
  let(:cluster_namespaces) { [] }
  let(:tfstate_namespaces) { [] }
  let(:infra_namespaces) { [] }

  let(:github_lister) { double(GithubNamespaceLister, namespace_names: github_namespaces) }
  let(:infrastructure_namespace_lister) { double(InfrastructureNamespaceLister, namespace_names: infra_namespaces) }

  let(:params) {
    {
      cluster_name: "foo",
      kubeconfig: double(fetch: true),
      tfstate_lister: double(namespaces: tfstate_namespaces),
      cluster_lister: double(namespace_names: cluster_namespaces),
      github_lister: github_lister,
      infrastructure_namespace_lister: infrastructure_namespace_lister,
    }
  }

  subject(:checker) { described_class.new(params) }

  before do
    allow_any_instance_of(Kubeconfig).to receive(:fetch_and_store).and_return(true)
  end

  context "when github lister returns empty list" do
    let(:github_namespaces) { [] }

    it "raises an error" do
      expect {
        checker.report
      }.to raise_error(RuntimeError, "No github repositories returned. Aborting")
    end
  end

  context "when every namespace has source code" do
    let(:github_namespaces) { ["is-in-github"] }
    let(:cluster_namespaces) { ["is-in-github"] }

    it "produces no output" do
      expect(checker.report).to eq("")
    end
  end

  context "when a namespace has no source code" do
    let(:github_namespaces) { ["is-in-github"] }
    let(:cluster_namespaces) { ["is-in-github", "has-no-source-code"] }

    it "includes namespace in the report" do
      expected = <<~EOF
        Namespaces in cluster foo with no source code in the cloud-platform-environments repository:

        has-no-source-code

      EOF
      expect(checker.report).to eq(expected)
    end

    context "but it is an infrastructure namespace" do
      let(:infra_namespaces) { ["has-no-source-code"] }

      it "produces no output" do
        expect(checker.report).to eq("")
      end
    end
  end

  context "when orphan namespace has AWS resources" do
    let(:github_namespaces) { ["is-in-github"] }
    let(:cluster_namespaces) { ["is-in-github", "has-no-source-code"] }

    let(:aws_resources) {
      [
        {type: "s3-bucket", id: 1},
        {type: "rds-instance", id: 2},
      ]
    }
    let(:namespace) { double(name: "has-no-source-code", aws_resources: aws_resources) }
    let(:tfstate_namespaces) { [namespace] }

    it "lists the AWS resources" do
      expected = <<~EOF
        Namespaces in cluster foo with no source code in the cloud-platform-environments repository:

        has-no-source-code
          AWS Resources:
            s3-bucket: 1
            rds-instance: 2

      EOF
      expect(checker.report).to eq(expected)
    end
  end
end
