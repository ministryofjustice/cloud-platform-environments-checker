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
        TFState.new($1)
      end
    end.compact
  end
end
