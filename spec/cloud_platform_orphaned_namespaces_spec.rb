RSpec.describe CloudPlatformOrphanNamespaces do
  let(:params) { { github_lister: github_lister } }
  subject(:checker) { described_class.new(params) }

  context "when github lister returns empty list" do
    let(:github_lister) { double(GithubNamespaceLister, namespace_names: []) }

    it "raises an error" do
      expect {
        checker.report
      }.to raise_error(RuntimeError, "No github repositories returned. Aborting")
    end
  end
end
