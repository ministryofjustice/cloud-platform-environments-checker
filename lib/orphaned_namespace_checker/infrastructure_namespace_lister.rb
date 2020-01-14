class InfrastructureNamespaceLister
  # Return a list of all the namespaces which are created by the terraform
  # code in the infrastructure repo.
  INFRASTRUCTURE_REPO = "https://github.com/ministryofjustice/cloud-platform-infrastructure.git"

  def namespace_names
    rtn = []

    Dir.mktmpdir do |dir|
      system("git clone --depth 1 #{INFRASTRUCTURE_REPO} #{dir}")

      # output all lines which look like they create a namespace in the cluster
      # e.g.
      #
      #     resource "kubernetes_namespace" "opa" {
      #
      lines = `find #{dir} -name '*.tf' | xargs grep -h 'kubernetes_namespace.*{'`

      # return a list of namespace names, by grabbing the contents of the last
      # set of double-quotes
      rtn = lines.split("\n").grep(/" "(.*)" {/) { $1 }
    end

    rtn
  end

end
