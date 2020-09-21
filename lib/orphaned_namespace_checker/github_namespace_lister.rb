class GithubNamespaceLister
  attr_reader :env_repo, :cluster_name, :github_token

  def initialize(args)
    @env_repo = args.fetch(:env_repo)
    @cluster_name = args.fetch(:cluster_name)
    @github_token = args.fetch(:github_token)
  end

  def namespace_exists?(namespace)
    namespace_names.include?(namespace)
  end

  def namespace_names
    env_repo_namespace_path = "https://api.github.com/repos/ministryofjustice/#{env_repo}/contents/namespaces/#{cluster_name}"
    content = open(env_repo_namespace_path, "Authorization" => "token #{github_token}").read
    JSON.parse(content).map { |hash| hash.fetch("name") }
  end

  def namespace_details
    env_repo_namespace_path = "https://api.github.com/repos/ministryofjustice/#{env_repo}/contents/namespaces/#{cluster_name}"
    content = open(env_repo_namespace_path, "Authorization" => "token #{github_token}").read
    #JSON.parse(content).map { |hash| hash.fetch("name") }
  end


  def repo_urls
    get_namespaces
      .map { |namespace| namespace.dig("metadata", "annotations", "cloud-platform.justice.gov.uk/source-code") }
      .compact
      .uniq
      .find_all { |url| REPO_REGEXP.match?(url) }
  end

  def get_namespaces
    stdout, _stderr, _status = executor.execute("kubectl get ns -o json", silent: true)
    JSON.parse(stdout).fetch("items")
  end
  
end
