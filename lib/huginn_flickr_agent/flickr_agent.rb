module Agents
  class FlickrAgent < Agent
    default_schedule '12h'

    description <<-MD
      Add a Agent description here
    MD

    def default_options
      {
      }
    end

    def validate_options
    end

    def working?
      checked_without_error?
      # received_event_without_error?
    end

#    def check
#    end

#    def receive(incoming_events)
#    end
  end
end
