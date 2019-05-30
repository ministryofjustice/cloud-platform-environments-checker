RSpec.describe CloudPlatformOrphanNamespaces do
  let(:cluster_namespaces) { [] }

  let(:params) { {
    cluster_name:    'foo',
    kubeconfig:      double(Object, fetch:            true),
    tfstate_lister:  double(Object, namespaces:       []),
    cluster_lister:  double(Object, namespace_names:  cluster_namespaces),
    github_lister:   github_lister,
  } }

  let(:github_lister) { double(GithubNamespaceLister, namespace_names: github_namespaces) }

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
    let(:github_namespaces) { ['is-in-github'] }
    let(:cluster_namespaces) { ['is-in-github'] }

    it "produces no output" do
      expect(checker.report).to eq('')
    end
  end

  context "when a namespace has no source code" do
    let(:github_namespaces)  { ['is-in-github'] }
    let(:cluster_namespaces) { ['is-in-github', 'has-no-source-code'] }

    it "includes namespace in the report" do
      expected = <<~EOF
      Namespaces in cluster foo with no source code in the cloud-platform-environments repository:

      has-no-source-code

      EOF
      expect(checker.report).to eq(expected)
    end
  end
end
