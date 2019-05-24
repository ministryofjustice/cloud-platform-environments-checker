class CloudPlatformOrphanNamespaces
  attr_reader :bucket_prefix, :tfstate_s3, :kubeconfig_s3

  def initialize(args = {})
    @tfstate_s3 = Aws::S3::Client.new(
      region: ENV.fetch('TFSTATE_AWS_REGION'),
      credentials: Aws::Credentials.new(
        ENV.fetch('TFSTATE_AWS_ACCESS_KEY_ID'),
        ENV.fetch('TFSTATE_AWS_SECRET_ACCESS_KEY')
      )
    )

    @kubeconfig_s3 = Aws::S3::Client.new(
      region: ENV.fetch('KUBECONFIG_AWS_REGION'),
      credentials: Aws::Credentials.new(
        ENV.fetch('KUBECONFIG_AWS_ACCESS_KEY_ID'),
        ENV.fetch('KUBECONFIG_AWS_SECRET_ACCESS_KEY')
      )
    )

    config_s3_location = {bucket: ENV.fetch('KUBECONFIG_S3_BUCKET'), key: ENV.fetch('KUBECONFIG_S3_KEY') }
    local_kubeconfig = ENV.fetch('KUBECONFIG')
    fetch_and_store_kubeconfig(config_s3_location, local_kubeconfig)

    @github_lister = args.fetch(
      :github_lister,
      GithubNamespaceLister.new(
        env_repo: 'cloud-platform-environments',
        cluster_name: ENV.fetch('PIPELINE_CLUSTER')
      )
    )

    @tfstate_lister = args.fetch(
      :tfstate_lister,
      TFStateNamespaceLister.new(
        bucket: ENV.fetch('PIPELINE_STATE_BUCKET'),
        bucket_prefix: ENV.fetch('BUCKET_PREFIX')
      )
    )

    @cluster_lister = args.fetch(
      :cluster_lister,
      ClusterNamespaceLister.new(kubeconfig: local_kubeconfig)
    )

    @bucket_prefix = ENV.fetch('BUCKET_PREFIX')

    @env_repo     = 'cloud-platform-environments'
    @state_bucket = ENV.fetch('PIPELINE_STATE_BUCKET')
  end

  def report
    rtn = []
    namespaces_with_tfstate = @tfstate_lister.namespaces
    orphan_namespace_names = namespace_names_with_no_source_code

    if orphan_namespace_names.any?
      rtn << "Namespaces in cluster with no source code in the #{@env_repo} repository:\n"
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

  # Get the kube config file from S3 and put it somewhere
  # we can read from
  def fetch_and_store_kubeconfig(s3_location, target_location)
    config = kubeconfig_s3.get_object(s3_location)
    File.open(target_location, 'w') do |f|
      f.puts config.body.read
    end
  end

end
