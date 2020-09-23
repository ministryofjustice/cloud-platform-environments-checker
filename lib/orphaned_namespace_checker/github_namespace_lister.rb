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
  
end
