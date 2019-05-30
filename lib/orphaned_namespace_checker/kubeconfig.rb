class Kubeconfig
  attr_reader :region, :aws_access_key_id, :aws_secret_access_key, :bucket, :key

  def initialize(args)
    @region                = args.fetch(:region)
    @aws_access_key_id     = args.fetch(:aws_access_key_id)
    @aws_secret_access_key = args.fetch(:aws_secret_access_key)
    @bucket                = args.fetch(:bucket)
    @key                   = args.fetch(:key)
  end

  # The kubernetes config file is stored in S3 under the AWS Cloud Platform account.
  # Copy it to `target_location`
  def fetch_and_store(target_location)
    s3 = Aws::S3::Client.new(
      region: region,
      credentials: Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
    )
    config = s3.get_object(bucket: bucket, key: key)

    File.open(target_location, 'w') { |f| f.puts(config.body.read) }
  end
end
