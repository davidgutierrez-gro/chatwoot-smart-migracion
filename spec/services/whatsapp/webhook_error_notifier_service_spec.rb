require 'rails_helper'

describe Whatsapp::WebhookErrorNotifierService do
  describe '.notify_if_needed' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account, name: 'WhatsApp TMK') }
    let(:conversation) { instance_double(Conversation, display_id: 56) }
    let(:agent) { instance_double(User, name: 'Juan Perez') }
    let(:record) do
      instance_double(
        WhatsappTemplateLog,
        error_code: 131026,
        error_message: 'Message undeliverable',
        conversation_id: 1234,
        conversation: conversation,
        inbox_id: inbox.id,
        phone_number: '+521234567890',
        template_name: 'hello_world',
        user_id: 3,
        user: agent
      )
    end
    let(:failures_scope) { instance_double(ActiveRecord::Relation) }
    let(:webhook_url_config) { 'https://hooks.example.com/wa-errors' }
    let(:threshold_config) { '5' }
    let(:window_config) { '10' }

    before do
      allow(GlobalConfigService).to receive(:load) do |config_key, _default_value|
        case config_key
        when 'WA_ERROR_WEBHOOK_URL'
          webhook_url_config
        when 'WA_ERROR_THRESHOLD'
          threshold_config
        when 'WA_ERROR_WINDOW_MINUTES'
          window_config
        end
      end
    end

    context 'when webhook URL is configured globally' do
      before do
        allow(WhatsappTemplateLog).to receive(:recent_failures).with(inbox.id, minutes: 10).and_return(failures_scope)
        allow(failures_scope).to receive(:where).with(error_code: 131026).and_return(failures_scope)
        allow(failures_scope).to receive(:count).and_return(1)
      end

      it 'sends a non-recurring webhook payload' do
        expect(WebhookJob).to receive(:perform_later).with(
          'https://hooks.example.com/wa-errors',
          hash_including(
            event: 'whatsapp_template_error',
            error_code: 131026,
            error_message: 'Message undeliverable',
            conversation_id: 1234,
            conversation_display_id: 56,
            inbox_id: inbox.id,
            inbox_name: 'WhatsApp TMK',
            template_name: 'hello_world',
            account_id: account.id,
            is_recurring: false,
            recurrence_count: 1,
            window_minutes: 10
          )
        )

        described_class.notify_if_needed(record: record, inbox: inbox, account: account)
      end
    end

    context 'when the same error repeats above threshold' do
      let(:threshold_config) { '2' }
      let(:window_config) { '15' }

      before do
        allow(record).to receive(:error_code).and_return(nil)
        allow(WhatsappTemplateLog).to receive(:recent_failures).with(inbox.id, minutes: 15).and_return(failures_scope)
        allow(failures_scope).to receive(:where).with(error_message: 'Message undeliverable').and_return(failures_scope)
        allow(failures_scope).to receive(:count).and_return(2)
      end

      it 'sends a recurring webhook payload' do
        expect(WebhookJob).to receive(:perform_later).with(
          'https://hooks.example.com/wa-errors',
          hash_including(
            event: 'whatsapp_template_recurring_error',
            is_recurring: true,
            recurrence_count: 2,
            window_minutes: 15
          )
        )

        described_class.notify_if_needed(record: record, inbox: inbox, account: account)
      end
    end

    context 'when threshold/window configs are invalid' do
      let(:threshold_config) { 'invalid' }
      let(:window_config) { '0' }

      before do
        allow(WhatsappTemplateLog).to receive(:recent_failures).with(inbox.id, minutes: 10).and_return(failures_scope)
        allow(failures_scope).to receive(:where).with(error_code: 131026).and_return(failures_scope)
        allow(failures_scope).to receive(:count).and_return(4)
      end

      it 'falls back to safe defaults' do
        expect(WebhookJob).to receive(:perform_later).with(
          'https://hooks.example.com/wa-errors',
          hash_including(
            event: 'whatsapp_template_error',
            is_recurring: false,
            recurrence_count: 4,
            window_minutes: 10
          )
        )

        described_class.notify_if_needed(record: record, inbox: inbox, account: account)
      end
    end

    context 'when no webhook URL is available' do
      let(:webhook_url_config) { nil }

      it 'skips notification without querying recurrence' do
        expect(WhatsappTemplateLog).not_to receive(:recent_failures)
        expect(WebhookJob).not_to receive(:perform_later)

        described_class.notify_if_needed(record: record, inbox: inbox, account: account)
      end
    end
  end
end
