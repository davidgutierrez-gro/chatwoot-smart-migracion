class WhatsappTemplateLog < ApplicationRecord
  belongs_to :account
  belongs_to :conversation, optional: true
  belongs_to :inbox, optional: true
  belongs_to :contact, optional: true
  belongs_to :user, optional: true
  belongs_to :message, optional: true

  validates :status, inclusion: { in: %w[sent failed delivered read] }

  scope :failed, -> { where(status: 'failed') }
  scope :recent_failures, ->(inbox_id, minutes: 10) {
    failed.where(inbox_id: inbox_id).where('created_at > ?', minutes.minutes.ago)
  }
end
