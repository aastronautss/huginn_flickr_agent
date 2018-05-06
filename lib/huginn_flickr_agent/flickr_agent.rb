# frozen_string_literal: true

module Agents
  ##
  # = Huginn Flickr agent
  #
  class FlickrAgent < Agent
    include FormConfigurable
    include FlickrAgentable

    cannot_receive_events!

    default_schedule 'every_1h'

    description <<-MD
      Checks the Flickr feed of the provided user and creates an event for each upload.
    MD

    form_configurable :username
    form_configurable :count
    form_configurable :history
    form_configurable :expected_update_period_in_days
    form_configurable :starting_at

    def default_options
      {
        'username' => 'me',
        'count' => '10',
        'history' => '100',
        'expected_update_period_in_days' => '2',

        'safe_search' => SS_RESTRICTED
      }
    end

    def validate_options
      errors.add(:base, 'username is required') unless options['username'].present?
      errors.add(:base, 'count is required') unless options['count'].present?
      errors.add(:base, 'history is required') unless options['history'].present?
      unless options['expected_update_period_in_days'].present?
        errors.add(:base, 'expected_update_period_in_days is required')
      end
      unless options['safe_search'].blank? || SAFE_SEARCH_OPTIONS.keys.include?(options['safe_search'])
        errors.add(:base, "safe_search must be #{SAFE_SEARCH_OPTIONS.keys.join(', ')}, or blank")
      end

      if options[:starting_at].present?
        Time.parse(options[:starting_at]) rescue errors.add(:base, 'Error parsing starting_at')
      end
    end

    def working?
      event_created_within?(interpolated['expected_update_period_in_days']) && checked_without_error?
    end

    def starting_at
      if interpolated[:starting_at].present?
        Time.parse(interpolated[:starting_at]) rescue created_at
      else
        created_at
      end
    end

    def check
      user_id = find_user_id_for_username(interpolated['username'])

      opts = {
        user_id: user_id,
        per_page: interpolated['count'],
        safe_search: interpolated['safe_search'],
        min_upload_date: starting_at.to_i,

        extras: 'description,owner_name,date_upload,date_taken,date_taken,url_o,url_m,url_n,url_z,url_c,url_l,url_h,url_k'
      }

      photos = flickr.people.getPhotos(opts)
      memory[:last_seen] ||= []

      photos.each do |photo|
        next if memory[:last_seen].include?(photo.id) || photo.dateupload.to_i < starting_at.to_i

        memory[:last_seen].push(photo.id)
        memory[:last_seen].shift if memory[:last_seen].length > interpolated['history'].to_i

        create_event payload: photo.to_hash
      end
    end
  end
end
