require 'faraday'
require 'yaml'
require 'json'

class WeiboPoster
  def initialize
    @config = YAML.load_file(File.expand_path(File.dirname(__FILE__) + '/../_config.yml'))
    @weibo_config = YAML.load_file(File.expand_path(File.dirname(__FILE__) + '/../weibo-config.yml'))
  end

  def post_weibo
    conn = Faraday.new(:url => "https://api.weibo.com")

    result = conn.post '/2/statuses/update.json',
                       :access_token => @weibo_config['access_token'],
                       :status => generate_post
    responseJSON = JSON.parse result.body

    if responseJSON['error_code']
      puts 'post weibo error:' + responseJSON['error']
    else
      puts "post weibo successfully"
    end

  end

  def post_TencentWeibo
    conn = Faraday.new(:url => "https://open.t.qq.com")

    result = conn.post '/api/t/add',
                       :oauth_consumer_key => @weibo_config['tencent_oauth_consumer_key'],
                       :access_token => @weibo_config['tencent_access_token'],
                       :oauth_version => @weibo_config['tencent_oauth_version'],
                       :openid => @weibo_config['tencent_openid'],
                       :content => generate_post,
                       :format => 'json'
    responseJSON = JSON.parse result.body
    if responseJSON['errcode'] == 1
      puts 'post TencentWeibo error:' + responseJSON['msg']
    else
      puts 'post TencentWeibo successfully'
    end
  end

  private

  def generate_post
    post_template = @weibo_config['post_template'].force_encoding("utf-8")
    post_template % {:blog_title => latest_blog_title, :blog_url => generate_blog_url}
  end

  def latest_blog_title
    title_line = IO.readlines(latest_blog_file_name)[2]
    title_line["title: ".length..title_line.length].force_encoding("utf-8")
  end

  def latest_blog_file_name
    blogs_path = File.expand_path(File.dirname(__FILE__) + '/../source/_posts')
    filtered_right_blog = Dir.glob(blogs_path + "/*").select { |f| f.match(/\.markdown/) }
    filtered_right_blog.max_by { |f| File.mtime(f) }
  end

  def generate_blog_url
    full_url = @config['url'] + "/blog/" + convert_to_blog_url(latest_blog_file_name)
    full_url.force_encoding("utf-8")
  end

  def convert_to_blog_url(post_file_name)
    #convert 2012-12-21-demo-blog.markdown file name to be normal blog url: 2012/12/21/demo-blog
    File.basename(post_file_name, ".markdown").gsub(/\d-/) { |s| s[0] + "/" }
  end
end

poster = WeiboPoster.new
poster.post_weibo
poster.post_TencentWeibo