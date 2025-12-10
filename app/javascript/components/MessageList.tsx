import React, { useEffect, useRef } from 'react';
import UserMessage from './UserMessage';
import SystemMessage from './SystemMessage';
import { Message } from '../types/message';

interface MessageListProps {
    messages: Message[];
    onBasketUpdate?: () => void;
}

const MessageList: React.FC<MessageListProps> = ({ messages, onBasketUpdate }) => {
    const messagesEndRef = useRef<HTMLDivElement>(null);

    // Auto-scroll to latest message
    useEffect(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, [messages]);

    // Handle empty state
    if (messages.length === 0) {
        return (
            <div className="h-full flex items-center justify-center p-6">
                <div className="text-center">
                    <div className="text-gray-400 mb-2">
                        <svg
                            className="mx-auto h-12 w-12"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth={2}
                                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                            />
                        </svg>
                    </div>
                    <h3 className="text-lg font-medium text-gray-900 mb-1">
                        Start a conversation
                    </h3>
                    <p className="text-sm text-gray-500">
                        Ask me to help you find products, manage your basket, or complete your order
                    </p>
                    <div className="mt-4 space-y-2">
                        <p className="text-xs text-gray-400">Try asking:</p>
                        <div className="flex flex-wrap gap-2 justify-center">
                            <span className="inline-block px-3 py-1 bg-gray-100 text-gray-700 text-xs rounded-full">
                                "Show me red shirts"
                            </span>
                            <span className="inline-block px-3 py-1 bg-gray-100 text-gray-700 text-xs rounded-full">
                                "What's in my basket?"
                            </span>
                            <span className="inline-block px-3 py-1 bg-gray-100 text-gray-700 text-xs rounded-full">
                                "Add 2 blue t-shirts"
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="h-full overflow-y-auto p-6 space-y-4">
            {messages.map((message) => (
                message.role === 'user' ? (
                    <UserMessage
                        key={message.id}
                        content={message.content}
                        timestamp={message.timestamp}
                    />
                ) : (
                    <SystemMessage
                        key={message.id}
                        content={message.content}
                        timestamp={message.timestamp}
                        uiContext={message.uiContext}
                        onBasketUpdate={onBasketUpdate}
                    />
                )
            ))}
            <div ref={messagesEndRef} />
        </div>
    );
};

export default MessageList;
