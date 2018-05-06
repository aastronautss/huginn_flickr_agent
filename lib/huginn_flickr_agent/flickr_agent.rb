# frozen_string_literal: true

module Agents
  ##
  # = Huginn Flickr agent
  #
  class FlickrAgent < Agent
    include FormConfigurable
    include FlickrAgentable

    cannot_receive_events!

    description <<-MD
      Checks the Flickr feed of the provided user and creates an event for each upload.

      #{flickr_dependencies_missing if dependencies_missing?}

      To be able to use this Agent you need to authenticate with Flickr in the [Services](/services) section first.

      You must also provide the `username` of the Flickr user--use `me` if you would like to retrieve your favorites. `number` refers to the number of latest favorites to monitor and `history` refers to the number of favorites that will be held in memory.

      Set `expected_update_period_in_days` to the maximum amount of time that you'd expect to pass between Events being created by this Agent.

      Set `starting_at` to the date/time (eg. `Mon Jun 02 00:38:12 +0000 2014`) you want to start receiving favorites from (default: agent's `created_at`)
    MD

    event_description <<~MD
      Events are the raw JSON provided by the Flickr API, with the following extras: `dateupload`, `datetaken`, `ownername`, `description`, `url_o`, `url_l`, and `photopage_url`. `url_o` and `url_l` are direct links to the original (if available) and resized image, respectively. Events will look like:

          {
            "id": "1859181898",
            "owner": "7531567@N00",
            "secret": "45ab547e",
            "server": "4737",
            "farm": 5,
            "title": "",
            "ispublic": 1,
            "isfriend": 0,
            "isfamily": 0,
            "description": "",
            "dateupload": "1514876027",
            "datetaken": "2017-12-10 16:17:26",
            "datetakengranularity": "0",
            "datetakenunknown": "0",
            "ownername": "some_user",
            "url_o": "https://farm5.staticflickr.com/some/url.jpg",
            "height_o": "4032",
            "width_o": "3024",
            "url_m": "https://farm5.staticflickr.com/some/url.jpg",
            "height_m": "500",
            "width_m": "375",
            "url_n": "https://farm5.staticflickr.com/some/url.jpg",
            "height_n": "320",
            "width_n": 240,
            "url_z": "https://farm5.staticflickr.com/some/url.jpg",
            "height_z": "640",
            "width_z": "480",
            "url_c": "https://farm5.staticflickr.com/some/url.jpg",
            "height_c": "800",
            "width_c": 600,
            "url_l": "https://farm5.staticflickr.com/some/url.jpg",
            "height_l": "1024",
            "width_l": "768",
            "url_h": "https://farm5.staticflickr.com/some/url.jpg",
            "height_h": "1600",
            "width_h": 1200,
            "url_k": "https://farm5.staticflickr.com/some/url.jpg",
            "height_k": "2048",
            "width_k": 1536,
            "photopage_url": "https://www.flickr.com/photos/7531567@N00/1859181898"
          }
    MD

    default_schedule 'every_1h'

    form_configurable :username
    form_configurable :count
    form_configurable :history
    form_configurable :expected_update_period_in_days
    form_configurable :starting_at
    form_configurable :safe_search, type: array, values: SAFE_SEARCH_OPTIONS.keys

    def working?
      event_created_within?(interpolated['expected_update_period_in_days']) && checked_without_error?
    end

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

    def starting_at
      if interpolated[:starting_at].present?
        Time.parse(interpolated[:starting_at]) rescue created_at
      else
        created_at
      end
    end

    def check
      photos = flickr.people.getPhotos(check_request_opts)
      memory[:last_seen] ||= []

      photos.each { |photo| handle_photo(photo) }
    end

    private

    def check_request_opts
      user_id = find_user_id_for_username(interpolated['username'])

      {
        user_id: user_id,
        per_page: interpolated['count'],
        safe_search: interpolated['safe_search'],
        min_upload_date: starting_at.to_i,

        extras: 'description,owner_name,date_upload,date_taken,date_taken,url_o,url_m,url_n,url_z,url_c,url_l,url_h,url_k'
      }
    end

    def handle_photo(photo)
      return if memory[:last_seen].include?(photo.id) || photo.dateupload.to_i < starting_at.to_i

      memory[:last_seen].push(photo.id)
      memory[:last_seen].shift if memory[:last_seen].length > interpolated['history'].to_i

      create_event payload: payload_for_photo(photo)
    end

    def payload_for_photo(photo)
      payload = photo.to_hash
      payload[:photopage_url] = photopage_url_for(photo)

      payload
    end
  end
end
