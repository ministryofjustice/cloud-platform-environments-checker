class TFStateNamespaceLister
  attr_reader :bucket, :bucket_prefix, :s3client

  FILTERED_AWS_RESOURCES = ["aws_iam_access_key"]

  TFState = Struct.new(:name, :aws_resources)

  def initialize(args)
    @bucket = args.fetch(:bucket)
    @bucket_prefix = args.fetch(:bucket_prefix)
    @s3client = args.fetch(:s3client)
  end

  # If a namespace is defined in the terraform state for the cluster
  # it means there are AWS resources associated with it.
  def namespaces
    tf_objects = s3client.list_objects(bucket: bucket)

    tf_objects.contents.map { |obj|
      regexp = %r{#{bucket_prefix}(.*)/terraform.tfstate}
      if regexp.match(obj.key)
        name = $1
        resources = aws_resources(name)
        # live-1.cloud-platform.service.justice.gov.uk/demo-app -> demo-app
        namespace = name.split("/").last
        TFState.new(namespace, resources)
      end
    }.compact
  end

  private

  def aws_resources(namespace_name)
    key = "#{bucket_prefix}#{namespace_name}/terraform.tfstate"
    tfstate = s3client.get_object(bucket: bucket, key: key)
    obj = JSON.parse tfstate.body.read

    rtn = []

    modules = obj.fetch("modules", [])

    modules.each do |tf_module|
      tf_module.fetch("resources").each do |resource|
        rtn << get_aws_type_and_id(resource)
      end
    end

    rtn.compact
  end

  def get_aws_type_and_id(resource)
    if is_aws_resource?(resource)
      hash = resource[1]
      return nil if FILTERED_AWS_RESOURCES.include?(hash["type"])
      {type: hash["type"], id: hash["primary"]["id"]}
    end
  end

  # resource_tuple: [<name>, <data hash>]
  def is_aws_resource?(resource_tuple)
    name, _hash = resource_tuple
    !!/^aws_/.match?(name)
  end
end
