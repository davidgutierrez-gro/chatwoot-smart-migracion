require 'rails_helper'

describe Whatsapp::TemplateLogService do
  describe '#log_failure' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:contact) { create(:contact, account: account) }
    let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: '+573001112233') }
    let(:conversation) do
      create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
    end
    let(:message) { create(:message, conversation: conversation, account: account, inbox: inbox) }

    it 'does not notify webhook when log record creation fails' do
      service = described_class.new(
        message: message,
        template_name: 'hello_world',
        template_params: { name: 'hello_world' }
      )

      allow(service).to receive(:create_log).and_return(nil)
      expect(Whatsapp::WebhookErrorNotifierService).not_to receive(:notify_if_needed)

      expect(service.log_failure(error_code: 131026, error_message: 'Message undeliverable')).to be_nil
    end
  end
end
