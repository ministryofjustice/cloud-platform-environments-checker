class TFStateNamespaceLister
  attr_reader :bucket, :bucket_prefix, :s3client

  TFState = Struct.new(:name, :aws_resources)

  def initialize(args)
    @bucket        = args.fetch(:bucket)
    @bucket_prefix = args.fetch(:bucket_prefix)
    @s3client      = args.fetch(:s3client, Aws::S3::Client.new(
      region: ENV.fetch('TFSTATE_AWS_REGION'),
      credentials: Aws::Credentials.new(
        ENV.fetch('TFSTATE_AWS_ACCESS_KEY_ID'),
        ENV.fetch('TFSTATE_AWS_SECRET_ACCESS_KEY')
      )
    ))
  end

  # If a namespace is defined in the terraform state for the cluster
  # it means there are AWS resources associated with it.
  def namespaces
    tf_objects = s3client.list_objects(bucket: bucket)

    tf_objects.contents.map do |obj|
      regexp = %r[#{bucket_prefix}/(.*)/terraform.tfstate]
      if regexp.match(obj.key)
        name = $1
        TFState.new(name, aws_resources(name))
      end
    end.compact
  end

  private

  def aws_resources(namespace_name)
    key = "#{bucket_prefix}/#{namespace_name}/terraform.tfstate"
    tfstate = s3client.get_object(bucket: bucket, key: key)
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
