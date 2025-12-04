require 'rails_helper'

RSpec.describe 'Api::Conversations', type: :request do
  let(:session_id) { 'test-session-123' }

  describe 'POST /api/conversations' do
    context 'with valid parameters' do
      it 'creates a new conversation' do
        expect {
          post '/api/conversations', params: { session_id: session_id }
        }.to change(Conversation, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['conversation_id']).to be_present
        expect(json['session_id']).to eq(session_id)
        expect(json['created_at']).to be_present
      end

      it 'creates conversation with empty messages array' do
        post '/api/conversations', params: { session_id: session_id }

        conversation = Conversation.last
        expect(conversation.messages).to eq([])
        expect(conversation.session_id).to eq(session_id)
      end
    end

    context 'with missing session_id' do
      it 'returns unprocessable entity error' do
        post '/api/conversations', params: {}

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('session_id is required')
      end
    end

    context 'with blank session_id' do
      it 'returns unprocessable entity error' do
        post '/api/conversations', params: { session_id: '' }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('session_id is required')
      end
    end
  end

  describe 'POST /api/conversations/:conversation_id/messages' do
    let!(:conversation) { Conversation.create_for_session(session_id) }

    context 'with valid parameters' do
      it 'sends a message and returns a response' do
        post "/api/conversations/#{conversation.id}/messages",
             params: { message: 'Hello, I need help', session_id: session_id }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['conversation_id']).to eq(conversation.id)
        expect(json['intent']).to be_present
        expect(json['response']).to be_present
        expect(json['data']).to be_a(Hash)
        expect(json['suggestions']).to be_an(Array)
      end

      it 'adds user message to conversation' do
        message_text = 'Show me red shirts'

        expect {
          post "/api/conversations/#{conversation.id}/messages",
               params: { message: message_text, session_id: session_id }
        }.to change { conversation.reload.message_count }.by(2) # user + assistant

        conversation.reload
        messages = conversation.messages
        user_message = messages[-2]
        expect(user_message['role']).to eq('user')
        expect(user_message['content']).to eq(message_text)
        expect(user_message['timestamp']).to be_present
      end

      it 'adds assistant response to conversation' do
        post "/api/conversations/#{conversation.id}/messages",
             params: { message: 'Hello', session_id: session_id }

        conversation.reload
        assistant_message = conversation.messages.last
        expect(assistant_message['role']).to eq('assistant')
        expect(assistant_message['content']).to be_present
        expect(assistant_message['intent']).to be_present
        expect(assistant_message['timestamp']).to be_present
      end

      it 'maintains conversation history across multiple messages' do
        post "/api/conversations/#{conversation.id}/messages",
             params: { message: 'First message', session_id: session_id }
        post "/api/conversations/#{conversation.id}/messages",
             params: { message: 'Second message', session_id: session_id }

        conversation.reload
        expect(conversation.message_count).to eq(4) # 2 user + 2 assistant
        expect(conversation.messages[0]['content']).to eq('First message')
        expect(conversation.messages[2]['content']).to eq('Second message')
      end
    end

    context 'with invalid conversation_id' do
      it 'returns not found error' do
        post '/api/conversations/99999/messages',
             params: { message: 'Hello', session_id: session_id }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Conversation not found')
      end
    end

    context 'with missing message' do
      it 'returns unprocessable entity error' do
        post "/api/conversations/#{conversation.id}/messages",
             params: { session_id: session_id }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('message is required')
      end
    end

    context 'with blank message' do
      it 'returns unprocessable entity error' do
        post "/api/conversations/#{conversation.id}/messages",
             params: { message: '', session_id: session_id }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('message is required')
      end
    end

    context 'with missing session_id' do
      it 'returns unprocessable entity error' do
        post "/api/conversations/#{conversation.id}/messages",
             params: { message: 'Hello' }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('session_id is required')
      end
    end
  end

  describe 'DELETE /api/conversations/:conversation_id' do
    let!(:conversation) { Conversation.create_for_session(session_id) }

    context 'with valid conversation_id' do
      it 'deletes the conversation' do
        expect {
          delete "/api/conversations/#{conversation.id}"
        }.to change(Conversation, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Conversation deleted')
      end

      it 'removes conversation from database' do
        delete "/api/conversations/#{conversation.id}"

        expect(Conversation.find_by(id: conversation.id)).to be_nil
      end
    end

    context 'with invalid conversation_id' do
      it 'returns not found error' do
        delete '/api/conversations/99999'

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Conversation not found')
      end
    end

    context 'with conversation containing messages' do
      it 'deletes conversation with all messages' do
        conversation.add_message('user', 'Hello')
        conversation.add_message('assistant', 'Hi there')

        expect {
          delete "/api/conversations/#{conversation.id}"
        }.to change(Conversation, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /api/conversations' do
    context 'with valid session_id' do
      let!(:conversation1) { Conversation.create_for_session(session_id) }
      let!(:conversation2) { Conversation.create_for_session(session_id) }
      let!(:other_conversation) { Conversation.create_for_session('other-session') }

      before do
        conversation1.add_message('user', 'First conversation')
        conversation2.add_message('user', 'Second conversation')
        conversation2.add_message('assistant', 'Response')
      end

      it 'lists all conversations for the session' do
        get '/api/conversations', params: { session_id: session_id }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['conversations']).to be_an(Array)
        expect(json['conversations'].length).to eq(2)
      end

      it 'returns conversations in descending order by created_at' do
        get '/api/conversations', params: { session_id: session_id }

        json = JSON.parse(response.body)
        conversations = json['conversations']
        expect(conversations[0]['conversation_id']).to eq(conversation2.id)
        expect(conversations[1]['conversation_id']).to eq(conversation1.id)
      end

      it 'includes conversation details' do
        get '/api/conversations', params: { session_id: session_id }

        json = JSON.parse(response.body)
        conversation_data = json['conversations'].first
        expect(conversation_data['conversation_id']).to be_present
        expect(conversation_data['session_id']).to eq(session_id)
        expect(conversation_data['message_count']).to be_present
        expect(conversation_data['created_at']).to be_present
        expect(conversation_data['updated_at']).to be_present
      end

      it 'includes correct message count' do
        get '/api/conversations', params: { session_id: session_id }

        json = JSON.parse(response.body)
        conversations = json['conversations']
        conv2 = conversations.find { |c| c['conversation_id'] == conversation2.id }
        expect(conv2['message_count']).to eq(2)
      end

      it 'does not include conversations from other sessions' do
        get '/api/conversations', params: { session_id: session_id }

        json = JSON.parse(response.body)
        conversation_ids = json['conversations'].map { |c| c['conversation_id'] }
        expect(conversation_ids).not_to include(other_conversation.id)
      end
    end

    context 'with session having no conversations' do
      it 'returns empty array' do
        get '/api/conversations', params: { session_id: 'new-session' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['conversations']).to eq([])
      end
    end

    context 'with missing session_id' do
      it 'returns unprocessable entity error' do
        get '/api/conversations'

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('session_id is required')
      end
    end

    context 'with blank session_id' do
      it 'returns unprocessable entity error' do
        get '/api/conversations', params: { session_id: '' }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('session_id is required')
      end
    end
  end
end
