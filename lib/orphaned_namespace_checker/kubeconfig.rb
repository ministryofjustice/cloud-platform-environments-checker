class Kubeconfig
  attr_reader :region, :aws_access_key_id, :aws_secret_access_key, :bucket, :key, :local_target

  def initialize(args)
    @region                = args.fetch(:region)
    @aws_access_key_id     = args.fetch(:aws_access_key_id)
    @aws_secret_access_key = args.fetch(:aws_secret_access_key)
    @bucket                = args.fetch(:bucket)
    @key                   = args.fetch(:key)
    @local_target          = args.fetch(:local_target)
  end

  def fetch_and_store
    s3 = Aws::S3::Client.new(
      region: region,
      credentials: Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
    )
    config = s3.get_object(bucket: bucket, key: key)

    File.open(local_target, 'w') { |f| f.puts(config.body.read) }
  end
end
