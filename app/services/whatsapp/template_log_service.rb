class Whatsapp::TemplateLogService
  WHATSAPP_TEMPLATE_LOGGER = ActiveSupport::Logger.new(Rails.root.join('log/whatsapp_templates.log'))

  def initialize(message:, template_name: nil, template_params: nil)
    @message = message
    @conversation = message.conversation
    @inbox = @conversation.inbox
    @account = @conversation.account
    @contact = @conversation.contact
    @template_name = template_name
    @template_params = template_params
  end

  def log_success(api_response: {})
    record = create_log('sent', api_response: api_response)
    write_to_file('SUCCESS', record)
    record
  end

  def log_failure(error_code: nil, error_message: nil, api_response: {})
    record = create_log('failed', error_code: error_code, error_message: error_message, api_response: api_response)
    write_to_file('FAILED', record)
    return record unless record.present?

    Whatsapp::WebhookErrorNotifierService.notify_if_needed(
      record: record,
      inbox: @inbox,
      account: @account
    )

    record
  end

  private

  def create_log(status, error_code: nil, error_message: nil, api_response: {})
    WhatsappTemplateLog.create!(
      account: @account,
      conversation: @conversation,
      inbox: @inbox,
      contact: @contact,
      user: Current.user.is_a?(User) ? Current.user : nil,
      message: @message,
      template_name: @template_name,
      template_params: @template_params || {},
      status: status,
      error_code: error_code,
      error_message: error_message,
      api_response: api_response,
      phone_number: @conversation.contact_inbox&.source_id
    )
  rescue StandardError => e
    Rails.logger.error "[WhatsappTemplateLog] Failed to create log: #{e.message}"
    nil
  end

  def write_to_file(level, record)
    return unless record

    WHATSAPP_TEMPLATE_LOGGER.info(
      "[#{Time.current.iso8601}] [#{level}] " \
      "account=#{@account.id} inbox=#{@inbox.id} " \
      "conversation=#{@conversation.display_id} " \
      "contact=#{@contact&.id} user=#{Current.user&.id} " \
      "template=#{@template_name} status=#{record.status} " \
      "error_code=#{record.error_code} error=#{record.error_message}"
    )
  rescue StandardError => e
    Rails.logger.error "[WhatsappTemplateLog] Failed to write file log: #{e.message}"
  end
end
