require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::FlickrAgent do
  before(:each) do
    @valid_options = Agents::FlickrAgent.new.default_options
    @checker = Agents::FlickrAgent.new(:name => "FlickrAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
