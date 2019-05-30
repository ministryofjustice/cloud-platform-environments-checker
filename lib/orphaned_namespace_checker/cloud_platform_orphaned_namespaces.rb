class CloudPlatformOrphanNamespaces
  attr_reader :bucket_prefix, :cluster_name

  ENVIRONMENTS_REPO = 'cloud-platform-environments'

  def initialize(args = {})
    @env_repo      = ENVIRONMENTS_REPO,
    @cluster_name  = env('PIPELINE_CLUSTER')
    @bucket_prefix = env('BUCKET_PREFIX')
    @state_bucket  = env('PIPELINE_STATE_BUCKET')

    local_kubeconfig = env('KUBECONFIG')

    # The kubernetes config file is stored in S3 under the AWS Cloud Platform account
    Kubeconfig.new(
      region:                env('KUBECONFIG_AWS_REGION'),
      bucket:                env('KUBECONFIG_S3_BUCKET'),
      key:                   env('KUBECONFIG_S3_KEY'),
      aws_access_key_id:     env('KUBECONFIG_AWS_ACCESS_KEY_ID'),
      aws_secret_access_key: env('KUBECONFIG_AWS_SECRET_ACCESS_KEY'),
    ).fetch_and_store(local_kubeconfig)

    @github_lister = args.fetch(:github_lister, GithubNamespaceLister.new(
                                                  env_repo: 'cloud-platform-environments',
                                                  cluster_name: cluster_name
                                                )
    )

    @tfstate_lister = args.fetch(:tfstate_lister, TFStateNamespaceLister.new(
                                                    bucket: env('PIPELINE_STATE_BUCKET'),
                                                    bucket_prefix: env('BUCKET_PREFIX')
                                                  )
    )

    @cluster_lister = args.fetch(:cluster_lister, ClusterNamespaceLister.new(kubeconfig: local_kubeconfig))
  end

  def report
    rtn = []
    namespaces_with_tfstate = @tfstate_lister.namespaces
    orphan_namespace_names = namespace_names_with_no_source_code

    if orphan_namespace_names.any?
      rtn << "Namespaces in cluster #{cluster_name} with no source code in the #{@env_repo} repository:\n"
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
    @cluster_lister.namespace_names - namespace_names_defined_in_git_repository
  end

  def namespace_names_defined_in_git_repository
    names = @github_lister.namespace_names
    raise "No github repositories returned. Aborting" if names.empty?
    names
  end

  def env(var)
    ENV.fetch(var)
  end
end
