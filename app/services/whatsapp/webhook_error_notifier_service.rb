class Whatsapp::WebhookErrorNotifierService
  DEFAULT_RECURRING_ERROR_THRESHOLD = 5
  DEFAULT_RECURRING_ERROR_WINDOW_MINUTES = 10
  WEBHOOK_SUBSCRIPTION_EVENT = 'whatsapp_template_error'

  def self.notify_if_needed(record:, inbox:, account:)
    new(record: record, inbox: inbox, account: account).perform
  end

  def initialize(record:, inbox:, account:)
    @record = record
    @inbox = inbox
    @account = account
  end

  def perform
    return if @record.blank? || @inbox.blank? || @account.blank? || webhook_url.blank?

    recent_count = recurring_error_count
    is_recurring = recent_count >= recurring_error_threshold

    payload = build_payload(is_recurring, recent_count)
    send_webhook(payload)
  end

  private

  def recurring_error_count
    recent_failures = WhatsappTemplateLog.recent_failures(@inbox.id, minutes: recurring_error_window_minutes)
    return recent_failures.where(error_code: @record.error_code).count if @record.error_code.present?
    return recent_failures.where(error_message: @record.error_message).count if @record.error_message.present?

    recent_failures.count
  end

  def webhook_url
    @webhook_url ||= configured_webhook_url || installable_webhook_url
  end

  def configured_webhook_url
    GlobalConfigService.load('WA_ERROR_WEBHOOK_URL', nil).presence
  rescue StandardError
    nil
  end

  def recurring_error_threshold
    @recurring_error_threshold ||= positive_integer_config('WA_ERROR_THRESHOLD', DEFAULT_RECURRING_ERROR_THRESHOLD)
  end

  def recurring_error_window_minutes
    @recurring_error_window_minutes ||= positive_integer_config(
      'WA_ERROR_WINDOW_MINUTES',
      DEFAULT_RECURRING_ERROR_WINDOW_MINUTES
    )
  end

  def positive_integer_config(config_key, fallback)
    value = GlobalConfigService.load(config_key, fallback).to_i
    value.positive? ? value : fallback
  rescue StandardError
    fallback
  end

  def installable_webhook_url
    # MOD-5: buscar por contencion (el webhook puede tener multiples subscriptions)
    @account.webhooks
            .where("subscriptions @> ?", [WEBHOOK_SUBSCRIPTION_EVENT].to_json)
            .order(id: :desc)
            .pick(:url)
  rescue StandardError
    nil
  end

  def build_payload(is_recurring, recurrence_count)
    {
      event: is_recurring ? 'whatsapp_template_recurring_error' : 'whatsapp_template_error',
      error_code: @record.error_code,
      error_message: @record.error_message,
      conversation_id: @record.conversation_id,
      conversation_display_id: @record.conversation&.display_id,
      inbox_id: @record.inbox_id,
      inbox_name: @inbox.name,
      contact_phone: @record.phone_number,
      template_name: @record.template_name,
      agent_id: @record.user_id,
      agent_name: @record.user&.name,
      account_id: @account.id,
      timestamp: Time.current.iso8601,
      is_recurring: is_recurring,
      recurrence_count: recurrence_count,
      window_minutes: recurring_error_window_minutes
    }
  end

  def send_webhook(payload)
    WebhookJob.perform_later(webhook_url, payload)
  rescue StandardError => e
    Rails.logger.error "[WebhookErrorNotifier] Failed to enqueue webhook: #{e.message}"
  end
end
