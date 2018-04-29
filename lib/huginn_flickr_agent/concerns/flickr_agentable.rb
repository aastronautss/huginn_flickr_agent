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
      defined?(FlickRaw::Flickr) &&
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
      elsif !defined?(FlickRaw) || !Devise.omniauth_providers.include?(:flickr)
        '## Include `flickr` and `omniauth-flickr` in your Gemfile to use Flickr agents.'
      end
    end
  end

  def validate_options
    return if flickr_oauth_token.present? && flickr_oauth_secret.present?

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

  def flickr_oauth_secret
    service&.secret
  end

  def flickr
    @flickr ||= FlickRaw::Flickr.new.tap do |flickr_client|
      flickr_client.access_token = flickr_oauth_token
      flickr_client.access_secret = flickr_oauth_secret
    end
  end

  def find_user_id_for_username(username)
    memory[:user_ids] ||= {}

    memory[:user_ids][username] = user_data_for_username(username)[:nsid] unless memory[:user_ids].key?(username)
    memory[:user_ids][username]
  end

  private

  def user_data_for_username(username)
    flickr.people.findByUsername(username: username).with_indifferent_access
  end
end
