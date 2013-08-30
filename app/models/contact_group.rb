class ContactGroup < ActiveRecord::Base
  extend ActiveHash::Associations::ActiveRecordExtensions

  has_many :contacts
  has_many :offices, through: :contacts
  has_many :questions, through: :offices
  belongs_to :contact_group_type

  acts_as_url :title, url_attribute: :slug, sync_url: true

  validates :title, presence: true
  validates :description, presence: true

  scope :most_popular, -> {
    where(contact_group_type_id: ContactGroupType.most_popular.id)
  }
  scope :except_most_popular, -> {
    where("contact_group_type_id != ?", ContactGroupType.most_popular.id)
  }
  scope :with_contacts, -> { includes(:contacts) }
  scope :with_offices, -> { with_contacts.includes(:offices) }
  scope :by_title, -> { order("title ASC") }

  def to_s
    title
  end
end