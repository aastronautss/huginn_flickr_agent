# frozen_string_literal: true

require 'huginn_agent'

require 'flickraw'
require 'omniauth-flickr'

##
# Configuration options for the Flickr agent.
#
module HuginnFlickrAgent
  I18n.load_path << "#{File.dirname(__FILE__)}/locales/devise.en.yml"

  Devise.setup do |config|
    key = ENV['FLICKR_OAUTH_KEY']
    secret = ENV['FLICKR_OAUTH_SECRET']

    if defined?(OmniAuth::Strategies::Flickr) && key.present? && secret.present?
      config.omniauth(:flickr, key, secret, scope: 'write')
    end
  end
end

HuginnAgent.load 'huginn_flickr_agent/concerns/flickr_agentable'
HuginnAgent.register 'huginn_flickr_agent/flickr_agent'
