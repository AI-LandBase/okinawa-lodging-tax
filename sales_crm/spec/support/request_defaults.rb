RSpec.configure do |config|
  config.before(:each, type: :request) do
    host! "example.com"
  end
end

module DefaultUserAgent
  def get(path, **kwargs)
    kwargs[:headers] = { "HTTP_USER_AGENT" => "Mozilla/5.0 (compatible; RSpec)" }.merge(kwargs[:headers] || {})
    super
  end

  def post(path, **kwargs)
    kwargs[:headers] = { "HTTP_USER_AGENT" => "Mozilla/5.0 (compatible; RSpec)" }.merge(kwargs[:headers] || {})
    super
  end

  def patch(path, **kwargs)
    kwargs[:headers] = { "HTTP_USER_AGENT" => "Mozilla/5.0 (compatible; RSpec)" }.merge(kwargs[:headers] || {})
    super
  end

  def put(path, **kwargs)
    kwargs[:headers] = { "HTTP_USER_AGENT" => "Mozilla/5.0 (compatible; RSpec)" }.merge(kwargs[:headers] || {})
    super
  end

  def delete(path, **kwargs)
    kwargs[:headers] = { "HTTP_USER_AGENT" => "Mozilla/5.0 (compatible; RSpec)" }.merge(kwargs[:headers] || {})
    super
  end
end

RSpec.configure do |config|
  config.include DefaultUserAgent, type: :request
end
