class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.client
    @client ||= SecClient.new
  end
  delegate :client, to: "self.class"
end
