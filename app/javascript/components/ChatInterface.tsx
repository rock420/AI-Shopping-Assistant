import React, { useState, useEffect, useRef } from 'react';
import api from '../utils/api';
import MessageList from './MessageList';
import MessageInput from './MessageInput';
import { Message } from '../types/message';
import { UI_ACTIONS, type UIContext } from '../types/actions';

interface ChatInterfaceProps {
    sessionId: string;
    onBasketUpdate: () => void;
}

const ChatInterface: React.FC<ChatInterfaceProps> = ({ sessionId, onBasketUpdate }) => {
    const [conversationId, setConversationId] = useState<number | null>(null);
    const [messages, setMessages] = useState<Message[]>([]);
    const [isLoading, setIsLoading] = useState<boolean>(false);
    const [error, setError] = useState<string | null>(null);
    const cleanupRef = useRef<(() => void) | null>(null);

    // Create conversation on mount
    useEffect(() => {
        const createConversation = async () => {
            try {
                const conversation = await api.conversations.create();
                setConversationId(conversation.id);
            } catch (err: any) {
                console.error('Error creating conversation:', err);
                setError('Failed to start conversation. Please refresh the page.');
            }
        };

        createConversation();
    }, []);

    // Handle sending a message
    const handleSendMessage = async (messageText: string) => {
        if (!conversationId || !messageText.trim()) return;

        // Add user message to the list
        const userMessage: Message = {
            id: `user-${Date.now()}`,
            role: 'user',
            content: messageText,
            timestamp: new Date(),
        };
        setMessages(prev => [...prev, userMessage]);
        setIsLoading(true);
        setError(null);

        // Create assistant message placeholder
        const assistantMessageId = `assistant-${Date.now()}`;
        const assistantMessage: Message = {
            id: assistantMessageId,
            role: 'assistant',
            content: '',
            timestamp: new Date(),
        };
        setMessages(prev => [...prev, assistantMessage]);

        let accumulatedContent = '';

        // Cleanup previous SSE connection if exists
        if (cleanupRef.current) {
            cleanupRef.current();
        }

        // Send message and handle streaming response
        const cleanup = api.conversations.sendMessage(
            conversationId,
            messageText,
            // onContent
            (content: string) => {
                accumulatedContent += content;
                setMessages(prev =>
                    prev.map(msg =>
                        msg.id === assistantMessageId
                            ? { ...msg, content: accumulatedContent }
                            : msg
                    )
                );
            },
            // onUIContext
            (uiContext: UIContext) => {
                setMessages(prev =>
                    prev.map(msg =>
                        msg.id === assistantMessageId
                            ? { ...msg, uiContext }
                            : msg
                    )
                );
                // Refresh basket if UI context suggests basket changes
                if (uiContext.action === UI_ACTIONS.SHOW_BASKET) {
                    onBasketUpdate();
                }
            },
            // onDone
            () => {
                setIsLoading(false);
                cleanupRef.current = null;
            },
            // onError
            (errorMessage: string) => {
                setError(errorMessage);
                setIsLoading(false);
                // Remove the empty assistant message on error
                setMessages(prev => prev.filter(msg => msg.id !== assistantMessageId));
                cleanupRef.current = null;
            }
        );

        cleanupRef.current = cleanup;
    };

    // Handle starting a new conversation
    const handleNewConversation = async () => {
        try {
            // Create new conversation
            const conversation = await api.conversations.create();
            setConversationId(conversation.id);
            setMessages([]);
            setError(null);
        } catch (err: any) {
            console.error('Error starting new conversation:', err);
            setError('Failed to start new conversation. Please try again.');
        }
    };

    if (!conversationId && !error) {
        return (
            <div className="bg-white rounded-lg shadow p-6">
                <div className="flex items-center justify-center h-96">
                    <div className="text-gray-600">Starting conversation...</div>
                </div>
            </div>
        );
    }

    return (
        <div className="bg-white rounded-lg shadow flex flex-col h-[600px]">
            {/* Header */}
            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
                <h2 className="text-xl font-semibold text-gray-900">Chat Assistant</h2>
                <button
                    onClick={handleNewConversation}
                    className="px-3 py-1 text-sm text-blue-600 hover:text-blue-700 hover:bg-blue-50 rounded-md transition-colors"
                    disabled={isLoading}
                >
                    New Conversation
                </button>
            </div>

            {/* Error message */}
            {error && (
                <div className="mx-6 mt-4 p-3 bg-red-50 border border-red-200 rounded-md">
                    <p className="text-sm text-red-800">{error}</p>
                </div>
            )}

            {/* Messages */}
            <div className="flex-1 overflow-hidden">
                <MessageList messages={messages} />
            </div>

            {/* Input */}
            <div className="border-t border-gray-200">
                <MessageInput
                    onSend={handleSendMessage}
                    disabled={isLoading || !conversationId}
                    isLoading={isLoading}
                />
            </div>
        </div>
    );
};

export default ChatInterface;
