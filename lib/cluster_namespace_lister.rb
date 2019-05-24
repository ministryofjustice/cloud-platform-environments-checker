class ClusterNamespaceLister
  attr_reader :kubeconfig

  K8S_DEFAULT_NAMESPACES = %w(
    cert-manager
    default
    ingress-controllers
    kiam
    kube-public
    kube-system
    kuberos
    opa
  )

  def initialize(args)
    @kubeconfig = Kubeclient::Config.read args.fetch(:kubeconfig)
  end

  def namespace_names
    # This will always use whatever is the current context
    # in the kube config file
    context = kubeconfig.context

    client = Kubeclient::Client.new(
      context.api_endpoint,
      'v1',
      ssl_options: context.ssl_options,
      auth_options: context.auth_options
    )

    client.get_namespaces.map {
      |n| n.metadata.name
    } - K8S_DEFAULT_NAMESPACES
  end

end
