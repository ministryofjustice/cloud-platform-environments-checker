RSpec.describe ClusterNamespaceLister do
  let(:name_a) { double(name: 'aaa') }
  let(:name_b) { double(name: 'bbb') }
  let(:name_ks) { double(name: 'kube-system') }

  let(:ns_a) { double(metadata: name_a) }
  let(:ns_b) { double(metadata: name_b) }
  let(:ns_ks) { double(metadata: name_ks) }

  let(:namespaces) { [ns_a, ns_b, ns_ks] }

  let(:params) { {
    config_file: 'foo',
    context: 'whatever'
  } }

  let(:kubeclient) { double(get_namespaces: namespaces) }
  let(:context)    { double(api_endpoint: nil, ssl_options: nil, auth_options: nil) }
  let(:kubeconfig) { double(context: context) }

  subject(:lister) { described_class.new(params) }

  before do
    allow(Kubeclient::Config).to receive(:read).and_return(kubeconfig)
    allow(Kubeclient::Client).to receive(:new).and_return(kubeclient)
  end

  it "does not list system namespaces" do
    expect(lister.namespace_names).to eq(['aaa', 'bbb'])
  end
end
