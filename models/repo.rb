class Repo < ActiveRecord::Base
  acts_as_singleton

  belongs_to :commit
end
