class CreateWhatsappTemplateLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :whatsapp_template_logs do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :conversation, null: true, foreign_key: true, index: true
      t.references :inbox, null: true, foreign_key: true, index: true
      t.references :contact, null: true, foreign_key: true, index: true
      t.references :user, null: true, foreign_key: true
      t.references :message, null: true, foreign_key: true

      t.string :template_name
      t.jsonb :template_params, default: {}
      t.string :status, default: 'sent', null: false
      t.integer :error_code
      t.string :error_message
      t.jsonb :api_response, default: {}
      t.string :phone_number

      t.timestamps
    end

    add_index :whatsapp_template_logs, [:account_id, :status]
    add_index :whatsapp_template_logs, [:account_id, :created_at]
    add_index :whatsapp_template_logs, [:inbox_id, :status, :created_at], name: 'index_wa_template_logs_on_inbox_status_created'
  end
end
