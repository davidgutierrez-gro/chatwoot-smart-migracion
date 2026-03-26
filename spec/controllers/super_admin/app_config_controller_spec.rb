require 'rails_helper'

RSpec.describe 'Super Admin Application Config API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/app_config' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/app_config'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      let!(:config) { create(:installation_config, { name: 'FB_APP_ID', value: 'TESTVALUE' }) }

      it 'shows the app_config page' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/app_config?config=facebook'
        expect(response).to have_http_status(:success)
        expect(response.body).to include(config.value)
      end
    end
  end

  describe 'POST /super_admin/app_config' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        post '/super_admin/app_config', params: { app_config: { TESTKEY: 'TESTVALUE' } }
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an aunthenticated super admin' do
      it 'shows the app_config page' do
        sign_in(super_admin, scope: :super_admin)
        post '/super_admin/app_config?config=facebook', params: { app_config: { FB_APP_ID: 'FB_APP_ID' } }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(super_admin_settings_path)

        config = GlobalConfig.get('FB_APP_ID')
        expect(config['FB_APP_ID']).to eq('FB_APP_ID')
      end

      it 'updates WhatsApp template error webhook configs from Super Admin' do
        sign_in(super_admin, scope: :super_admin)
        post '/super_admin/app_config?config=whatsapp_embedded',
             params: {
               app_config: {
                 WA_ERROR_WEBHOOK_URL: 'https://hooks.example.com/wa-errors',
                 WA_ERROR_THRESHOLD: '7',
                 WA_ERROR_WINDOW_MINUTES: '20'
               }
             }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(super_admin_settings_path)

        config = GlobalConfig.get('WA_ERROR_WEBHOOK_URL', 'WA_ERROR_THRESHOLD', 'WA_ERROR_WINDOW_MINUTES')
        expect(config['WA_ERROR_WEBHOOK_URL']).to eq('https://hooks.example.com/wa-errors')
        expect(config['WA_ERROR_THRESHOLD']).to eq('7')
        expect(config['WA_ERROR_WINDOW_MINUTES']).to eq('20')
      end
    end
  end
end
