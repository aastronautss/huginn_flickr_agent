# frozen_string_literal: true

##
# A mixin for adding Flickr API functionality to Huginn agents.
#
module FlickrAgentable
  extend ActiveSupport::Concern

  included do
    include FormConfigurable
    include Oauthable

    valid_oauth_providers :flickr

    gem_dependency_check do
      defined?(Flickr::Client) &&
        Devise.omniauth_providers.include?(:flickr) &&
        ENV['FLICKR_OAUTH_KEY'].present? &&
        ENV['FLICKR_OAUTH_SECRET'].present?
    end

    description <<~MD
      To be able to use this Agent you need to authenticate with Flickr in the [Services](/services) section first.
    MD
  end

  module ClassMethods
    def flickr_dependencies_missing
      if ENV['FLICKR_OAUTH_KEY'].blank? || ENV['FLICKR_OAUTH_SECRET'].blank?
        '## Set FLICKR_OAUTH_KEY and FLICKR_OAUTH_SECRET in your environment to use Flickr agents.'
      elsif !defined?(Flickr) || !Devise.omniauth_providers.include?(:flickr)
        '## Include `flickr` and `omniauth-flickr` in your Gemfile to use Flickr agents.'
      end
    end
  end

  def validate_options
    return if flickr_oauth_token.present?

    errors.add(:base, 'You need to authenticate with Flickr in the Services section')
  end

  def flickr_consumer_key
    (config = Devise.omniauth_configs[:flickr]) && config.strategy.consumer_key
  end

  def flickr_consumer_secret
    (config = Devise.omniauth_configs[:flickr]) && config.strategy.consumer_secret
  end

  def flickr_oauth_token
    service&.token
  end

  def flickr
    Flickr::Client.new(flickr_oauth_token)
  end
end
