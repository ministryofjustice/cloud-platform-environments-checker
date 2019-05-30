class ClusterNamespaceLister
  attr_reader :config_file, :context

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
    @config_file = args.fetch(:config_file)
    @context     = args.fetch(:context)
  end

  def namespace_names
    kubeconfig = Kubeclient::Config.read(config_file)

    ctx = kubeconfig.context(context)

    client = Kubeclient::Client.new(
      ctx.api_endpoint,
      'v1',
      ssl_options: ctx.ssl_options,
      auth_options: ctx.auth_options
    )

    client.get_namespaces.map {
      |n| n.metadata.name
    } - K8S_DEFAULT_NAMESPACES
  end

end
