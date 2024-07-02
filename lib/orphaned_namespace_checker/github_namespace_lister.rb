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

  
  ## Retrieves a list of namespace names using GitHub Git Trees API
  def namespace_names
    env_repo_namespace_tree_path = "https://api.github.com/repos/ministryofjustice/#{env_repo}/git/trees/#{git_tree_sha}"
    tree = URI.open(env_repo_namespace_tree_path, "Authorization" => "token #{github_token}").read
    response = JSON.parse(tree)
    response["tree"].map { |hash| hash.fetch("path") }
  end

  private

  ## Fetch the latest sha hash of the namespace directory using GitHub Repositories Contents API, needed to contruct env_repo_namespace_tree_path
  def git_tree_sha
    env_repo_namespaces_content_url = "https://api.github.com/repos/ministryofjustice/#{env_repo}/contents/namespaces"
    content = URI.open(env_repo_namespaces_content_url, "Authorization" => "token #{github_token}").read
    response = JSON.parse(content)
    item = response.find { |hash| hash["name"] == "#{cluster_name}" }
    item["sha"]
  end
end
