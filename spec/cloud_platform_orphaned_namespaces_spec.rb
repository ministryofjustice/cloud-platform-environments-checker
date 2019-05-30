RSpec.describe CloudPlatformOrphanNamespaces do
  let(:params) { {
    cluster_name:    'foo',
    kubeconfig:      double(Object, fetch:            true),
    tfstate_lister:  double(Object, namespaces:       []),
    cluster_lister:  double(Object, namespace_names:  []),
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
end
