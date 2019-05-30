class CloudPlatformOrphanNamespaces
  attr_reader :cluster_name, :github_lister, :tfstate_lister, :cluster_lister

  ENVIRONMENTS_REPO = 'cloud-platform-environments'

  def initialize(args = {})
    @cluster_name  = env('PIPELINE_CLUSTER')
    kubeconfig     = args.fetch(:kubeconfig)

    Kubeconfig.new(kubeconfig).fetch_and_store

    @tfstate_lister = args.fetch(:tfstate_lister) do
        TFStateNamespaceLister.new(
          s3client: Aws::S3::Client.new(
            region: env('TFSTATE_AWS_REGION'),
            credentials: Aws::Credentials.new(env('TFSTATE_AWS_ACCESS_KEY_ID'), env('TFSTATE_AWS_SECRET_ACCESS_KEY'))
          ),
          bucket: env('PIPELINE_STATE_BUCKET'),
          bucket_prefix: env('BUCKET_PREFIX')
        )
    end

    @github_lister  = args.fetch(:github_lister,  GithubNamespaceLister.new(env_repo: ENVIRONMENTS_REPO, cluster_name: cluster_name))
    @cluster_lister = args.fetch(:cluster_lister, ClusterNamespaceLister.new(kubeconfig: kubeconfig.fetch(:local_target)))
  end

  def report
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

  def env(var)
    ENV.fetch(var)
  end
end
