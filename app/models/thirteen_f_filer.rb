class ThirteenFFiler < ApplicationRecord
  def readonly?
    true
  end

  paginates_per 200

  has_many :thirteen_fs, primary_key: :cik, foreign_key: :cik

  scope :autocomplete, -> (query) {
    where("name ILIKE ? OR cik = ?", "%#{query}%", query).
      order([Arel.sql("similarity(?, name) DESC, lower(name)"), query])
  }

  def self.refresh!
    Scenic.database.refresh_materialized_view(
      :thirteen_f_filers,
      concurrently: true
    )
  end

  def city_and_state
    [city&.titleize, state_or_country].compact.join(", ")
  end

  def self.to_param(cik, name)
    [cik, name].compact.join(" ").parameterize
  end

  def to_param
    self.class.to_param(cik, name)
  end

  def self.find_by_param!(param)
    find_by!(cik: param.split("-").first)
  end
end
