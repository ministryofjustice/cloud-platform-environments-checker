class ClusterNamespaceLister
  attr_reader :config_file, :context

  K8S_DEFAULT_NAMESPACES = %w[
    cert-manager
    default
    ingress-controllers
    kiam
    kube-node-lease
    kube-public
    kube-system
    kuberos
    opa
    velero
  ]

  def initialize(args)
    @config_file = args.fetch(:config_file)
    @context = args.fetch(:context)
  end

  def kubeclient
    kubeconfig = Kubeclient::Config.read(config_file)
    ctx = kubeconfig.context(context)
    Kubeclient::Client.new(
      ctx.api_endpoint,
      "v1",
      ssl_options: ctx.ssl_options,
      auth_options: ctx.auth_options
    )
  end

  def namespace_names
    kubeclient.get_namespaces.map { |n|
      n.metadata.name
    } - K8S_DEFAULT_NAMESPACES
  end

  def namespace_details
    kubeclient.get_namespaces.map { |n|
      annotations = n.metadata.to_h
    }
  end

  def get_ingresses
   
    stdout, _, _ = Open3.capture3("kubectl config use-context #{context}")

    stdout, stderr, status = Open3.capture3("kubectl get ingresses --all-namespaces -o json")
      unless status.success?
        raise stderr
      end
      JSON.parse(stdout).fetch("items")
  end

end
