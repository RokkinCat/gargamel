require 'octokit'
require 'sequel'
class User < Sequel::Model
  one_to_many :teams

  def github_client
    Octokit::Client.new(:access_token => self.github_access_token || self.github_oauth_access_token)
  end
end