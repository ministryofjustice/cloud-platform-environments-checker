class CloudPlatformOrphanNamespaces

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

  def initialize(args = {})
    @github_lister = args.fetch(
      :github_lister,
      GithubNamespaceLister.new(
        env_repo: 'cloud-platform-environments',
        cluster_name: ENV.fetch('PIPELINE_CLUSTER')
      )
    )

    @env_repo     = 'cloud-platform-environments'
    @state_bucket = ENV.fetch('PIPELINE_STATE_BUCKET')
    @cluster      = ENV.fetch('PIPELINE_CLUSTER')
    @kubeconfig   = Kubeclient::Config.read(ENV.fetch('KUBECONFIG'))
    @s3client     = Aws::S3::Client.new
  end

  def report
    rtn = []
    namespaces_with_tfstate = namespace_names_with_tfstate
    orphan_namespaces = namespace_names_with_no_source_code

    if orphan_namespaces.any?
      rtn << "Namespaces in cluster with no source code in the #{@env_repo} repository:\n"
    end

    orphan_namespaces.each do |name|
      rtn << name

      # If there is no terraform state associated with this namespace, then there
      # are no AWS resources to clean up
      if namespaces_with_tfstate.include?(name)
        rtn << "  AWS Resources:"
        aws_resources(name).each do |res|
          rtn << "    #{res[:type]}: #{res[:id]}"
        end
      end
      rtn << "\n"
    end

    rtn.join("\n")
  end

  private

  def namespace_names_with_no_source_code
    namespace_names_in_k8s_cluster - K8S_DEFAULT_NAMESPACES \
      - namespace_names_defined_in_git_repository
  end

  def namespace_names_defined_in_git_repository
    names = @github_lister.namespace_names
    raise "No github repositories returned. Aborting" if names.empty?
    names
  end

  def namespace_names_in_k8s_cluster
    # TODO: fix this - we won't have current context in the pipeline
    context = @kubeconfig.context

    client = Kubeclient::Client.new(
      context.api_endpoint,
      'v1',
      ssl_options: context.ssl_options,
      auth_options: context.auth_options
    )

    client.get_namespaces.map { |n| n.metadata.name }
  end

  # If a namespace is defined in the terraform state for the cluster
  # it means there are AWS resources associated with it.
  def namespace_names_with_tfstate
    tf_objects = @s3client.list_objects(bucket: @state_bucket)

    tf_objects.contents.map do |obj|
      regexp = %r[#{@env_repo}/#{@cluster}/(.*)/terraform.tfstate]
      if regexp.match(obj.key)
        $1
      end
    end.compact
  end

  def aws_resources(namespace_name)
    key = "#{@env_repo}/#{@cluster}/#{namespace_name}/terraform.tfstate"
    tfstate = @s3client.get_object(bucket: @state_bucket, key: key)
    obj = JSON.parse tfstate.body.read

    rtn = []

    obj.fetch('modules').each do |tf_module|
      tf_module.fetch('resources').each do |resource|
        rtn << get_aws_type_and_id(resource)
      end
    end

    rtn.compact
  end

  def get_aws_type_and_id(resource)
    if is_aws_resource?(resource)
      hash = resource[1]
      { type: hash['type'], id: hash['primary']['id'] }
    else
      nil
    end
  end

  # resource_hash usually has a single key, its name,
  # and a hash of data as the value.
  def is_aws_resource?(resource_hash)
    resource_hash.each do |name, hash|
      if name =~ /^aws_/
        return true
      end
    end
    false
  end
end
