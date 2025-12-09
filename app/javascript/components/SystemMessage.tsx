import React from 'react';
import { UI_ACTIONS, type UIContext } from '../types/actions';

interface SystemMessageProps {
    content: string;
    timestamp: Date;
    uiContext?: UIContext;
}

const SystemMessage: React.FC<SystemMessageProps> = ({ content, timestamp, uiContext }) => {
    const formatTime = (date: Date): string => {
        return date.toLocaleTimeString('en-US', {
            hour: 'numeric',
            minute: '2-digit',
            hour12: true
        });
    };

    return (
        <div className="flex justify-start">
            <div className="max-w-[80%]">
                <div className="bg-gray-100 text-gray-900 rounded-lg px-4 py-2 shadow-sm">
                    {content ? (
                        <p className="text-sm whitespace-pre-wrap break-words">{content}</p>
                    ) : (
                        <div className="flex items-center space-x-2">
                            <div className="animate-pulse flex space-x-1">
                                <div className="h-2 w-2 bg-gray-400 rounded-full"></div>
                                <div className="h-2 w-2 bg-gray-400 rounded-full"></div>
                                <div className="h-2 w-2 bg-gray-400 rounded-full"></div>
                            </div>
                            <span className="text-xs text-gray-500">Thinking...</span>
                        </div>
                    )}
                </div>
                <div className="mt-1 text-xs text-gray-500">
                    {formatTime(timestamp)}
                </div>
            </div>
        </div>
    );
};

export default SystemMessage;
