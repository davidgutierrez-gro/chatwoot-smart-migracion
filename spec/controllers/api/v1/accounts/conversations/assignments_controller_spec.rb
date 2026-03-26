require 'rails_helper'

RSpec.describe 'Conversation Assignment API', type: :request do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  describe 'POST /api/v1/accounts/{account.id}/conversations/<id>/assignments' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'returns unauthorized for assignee update' do
        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { assignee_id: agent.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['error']).to eq('Only administrators can assign conversations')
      end

      it 'returns unauthorized for team update' do
        team = create(:team, account: account)

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { team_id: team.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['error']).to eq('Only administrators can assign conversations')
      end
    end

    context 'when it is an authenticated administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:agent_bot) { create(:agent_bot, account: account) }
      let(:team) { create(:team, account: account) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'assigns a user to the conversation' do
        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { assignee_id: agent.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.assignee).to eq(agent)
      end

      it 'assigns an agent bot to the conversation' do
        params = { assignee_id: agent_bot.id, assignee_type: 'AgentBot' }

        expect(Conversations::AssignmentService).to receive(:new)
          .with(hash_including(conversation: conversation, assignee_id: agent_bot.id, assignee_type: 'AgentBot'))
          .and_call_original

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['name']).to eq(agent_bot.name)
        expect(conversation.reload.assignee_agent_bot).to eq(agent_bot)
        expect(conversation.reload.assignee).to be_nil
      end

      it 'assigns a team to the conversation' do
        team_member = create(:user, account: account, role: :agent, auto_offline: false)
        create(:inbox_member, inbox: conversation.inbox, user: team_member)
        create(:team_member, team: team, user: team_member)

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { team_id: team.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.team).to eq(team)
      end

      it 'unassigns the assignee from the conversation' do
        conversation.update!(assignee: agent)

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { assignee_id: nil },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.assignee).to be_nil
      end

      it 'unassigns the team from the conversation' do
        conversation.update!(team: team)

        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { team_id: 0 },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.team).to be_nil
      end
    end

    context 'when it is an authenticated bot' do
      let(:agent_bot) { create(:agent_bot, account: account) }
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:agent_bot_inbox, inbox: conversation.inbox, agent_bot: agent_bot)
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'returns unauthorized even with inbox access' do
        post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
             headers: { api_access_token: agent_bot.access_token.token },
             params: { assignee_id: agent.id },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['error']).to eq('Only administrators can assign conversations')
      end
    end
  end
end
