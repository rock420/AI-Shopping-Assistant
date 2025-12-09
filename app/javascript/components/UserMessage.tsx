import React from 'react';

interface UserMessageProps {
    content: string;
    timestamp: Date;
}

const UserMessage: React.FC<UserMessageProps> = ({ content, timestamp }) => {
    const formatTime = (date: Date): string => {
        return date.toLocaleTimeString('en-US', {
            hour: 'numeric',
            minute: '2-digit',
            hour12: true
        });
    };

    return (
        <div className="flex justify-end">
            <div className="max-w-[80%]">
                <div className="bg-blue-600 text-white rounded-lg px-4 py-2 shadow-sm">
                    <p className="text-sm whitespace-pre-wrap break-words">{content}</p>
                </div>
                <div className="mt-1 text-xs text-gray-500 text-right">
                    {formatTime(timestamp)}
                </div>
            </div>
        </div>
    );
};

export default UserMessage;
