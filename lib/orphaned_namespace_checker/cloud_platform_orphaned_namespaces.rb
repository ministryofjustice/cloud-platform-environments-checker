class CloudPlatformOrphanNamespaces
  attr_reader :cluster_name, :github_lister, :tfstate_lister, :cluster_lister, :kubeconfig

  ENVIRONMENTS_REPO = 'cloud-platform-environments'

  def initialize(args = {})
    @cluster_name   = args.fetch(:cluster_name)
    @kubeconfig     = args.fetch(:kubeconfig)
    @tfstate_lister = args.fetch(:tfstate_lister) { TFStateNamespaceLister.new(args.fetch(:tfstate)) }
    @github_lister  = args.fetch(:github_lister)  { GithubNamespaceLister.new(env_repo: ENVIRONMENTS_REPO, cluster_name: cluster_name) }
    @cluster_lister = args.fetch(:cluster_lister) { ClusterNamespaceLister.new(config_file: kubeconfig.fetch(:local_target), context: kubeconfig.fetch(:context)) }
  end

  def report
    Kubeconfig.new(kubeconfig).fetch_and_store

    rtn = []
    namespaces_with_tfstate = tfstate_lister.namespaces
    orphan_namespace_names  = namespace_names_with_no_source_code

    if orphan_namespace_names.any?
      rtn << "Namespaces in cluster #{cluster_name} with no source code in the #{ENVIRONMENTS_REPO} repository:\n"
    end

    orphan_namespace_names.each do |name|
      rtn << name
      tfstate = namespaces_with_tfstate.find {|n| n.name == name}
      if tfstate && tfstate.aws_resources.any?
        rtn << "  AWS Resources:"
        tfstate.aws_resources.each do |res|
          rtn << "    #{res[:type]}: #{res[:id]}"
        end
      end
      rtn << "\n"
    end

    rtn.join("\n")
  end

  private

  def namespace_names_with_no_source_code
    cluster_lister.namespace_names - namespace_names_defined_in_git_repository
  end

  def namespace_names_defined_in_git_repository
    names = github_lister.namespace_names
    raise "No github repositories returned. Aborting" if names.empty?
    names
  end
end
