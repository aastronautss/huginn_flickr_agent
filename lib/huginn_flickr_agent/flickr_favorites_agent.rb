# frozen_string_literal: true

module Agents
  ##
  # = Huginn Flickr Favorites agent
  #
  class FlickrFavoritesAgent < Agent
    include FlickrAgentable

    cannot_receive_events!

    description <<~MD
      The Flickr Favorites agent retrieves the favorites list of a specified Flickr user.

      #{flickr_dependencies_missing if dependencies_missing?}

      To be able to use this Agent you need to authenticate with Flickr in the [Services](/services) section first.

      You must also provide the `username` of the Flickr user, `number` of latest favorites to monitor and `history` as number of favorites that will be held in memory.

      Set `expected_update_period_in_days` to the maximum amount of time that you'd expect to pass between Events being created by this Agent.

      Set `starting_at` to the date/time (eg. `Mon Jun 02 00:38:12 +0000 2014`) you want to start receiving favorites from (default: agent's `created_at`)
    MD

    event_description <<~MD
      Events are the raw JSON provided by the Flickr API, with the following extras: `dateupload`, `datetaken`, `ownername`, `description`, `url_o`, the last of which is the URL for the image in its original upload resolution. Looks like:

          {
            "id": "97517896524",
            "owner": "28698345@N00",
            "secret": "132148e84d",
            "server": "954",
            "farm": 1,
            "title": "The title of the photo",
            "ispublic": 1,
            "isfriend": 0,
            "isfamily": 0,
            "description": "",
            "dateupload": "1524686005",
            "datetaken": "2018-04-24 01:03:10",
            "datetakengranularity": "0",
            "datetakenunknown": "0",
            "ownername": "The owner of the photo",
            "date_faved": "1524753471",
            "url_o": "https://farm1.staticflickr.com/some/url.jpg",
            "url_m": "https://farm1.staticflickr.com/some/url.jpg",
            "url_n": "https://farm1.staticflickr.com/some/url.jpg",
            "url_z": "https://farm1.staticflickr.com/some/url.jpg",
            "url_c": "https://farm1.staticflickr.com/some/url.jpg",
            "url_l": "https://farm1.staticflickr.com/some/url.jpg",
            "url_h": "https://farm1.staticflickr.com/some/url.jpg",
            "url_k": "https://farm1.staticflickr.com/some/url.jpg",
            "height_o": "1700",
            "width_o": "1500"
          }
    MD

    default_schedule 'every_1h'

    form_configurable :username
    form_configurable :count
    form_configurable :history
    form_configurable :expected_update_period_in_days
    form_configurable :starting_at

    def working?
      event_created_within?(interpolated['expected_update_period_in_days']) && !recent_error_logs?
    end

    def default_options
      {
        'username' => 'aastronautss',
        'count' => '10',
        'history' => '100',
        'expected_update_period_in_days' => '2'
      }
    end

    def validate_options
      errors.add(:base, 'username is required') unless options['username'].present?
      errors.add(:base, 'count is required') unless options['count'].present?
      errors.add(:base, 'history is required') unless options['history'].present?
      unless options['expected_update_period_in_days'].present?
        errors.add(:base, 'expected_update_period_in_days is required')
      end

      if options[:starting_at].present?
        Time.parse(options[:starting_at]) rescue errors.add(:base, "Error parsing starting_at")
      end
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
        min_fave_date: starting_at.to_i,

        extras: 'description,owner_name,date_uploaded,date_taken,url_o,url_m,url_n,url_z,url_c,url_l,url_h,url_k'
      }
      favorites = flickr.favorites.getList(opts)
      memory[:last_seen] ||= []

      favorites.each do |favorite|
        next if memory[:last_seen].include?(favorite.id) || favorite.date_faved.to_i < starting_at.to_i

        memory[:last_seen].push(favorite.id)
        memory[:last_seen].shift if memory[:last_seen].length > interpolated['history'].to_i
        create_event payload: favorite.to_hash
      end
    end
  end
end
