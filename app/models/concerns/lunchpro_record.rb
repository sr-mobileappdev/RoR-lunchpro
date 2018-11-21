module LunchproRecord
  extend ActiveSupport::Concern
  include ActiveRecord::Store

  included do
    # Always hide deleted records by default
    default_scope { where.not(status: 'deleted') }

    # Every core application record should have a status column
    enum status: { draft: Constants::STATUS_DRAFT, active: Constants::STATUS_ACTIVE, inactive: Constants::STATUS_INACTIVE, deleted: Constants::STATUS_DELETED, archived: Constants::STATUS_ARCHIVED, completed: Constants::STATUS_COMPLETED, pending: Constants::STATUS_PENDING }

		validates_presence_of :status # LWH: this default_scope guy above will exclude valid records with a null value.

  end

  module ClassMethods
    def __default_columns
      columns = {}
      column_names.each do |c|
        columns[c.to_sym] = c.humanize
      end

      return columns
    end

    # Find records using case insensative search, including potential wildcards ("*" or "%")
    def find_match(params)
      at = self.arel_table
      relation = self
      params.each do |k,v|
        relation = (v.include?("*") || v.include?("%")) ? relation.where(at[k].matches(v.gsub("*","%"))) : relation = relation.where(at[k].matches(v))
      end
      relation
    end

  end
  def status__light
    if active?
      "on"
    else
      "off"
    end
  end

  def states
    ["AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC",  
    "DE", "FL", "GA", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA",  
    "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE",  
    "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI", "SC",  
    "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY"]
  end

  #format day of weeks enum into array of objects to be used in selectize
  def self.formatted_day_of_weeks(humanize = true)
    AppointmentSlot.day_of_weeks.collect{|k, v| {name: (humanize ? k.humanize : k), value: v}}
  end
end
