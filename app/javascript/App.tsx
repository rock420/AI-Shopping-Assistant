import React, { useState, useEffect } from 'react';
import { getSessionId } from './utils/session';
import api from './utils/api';
import type { Basket } from './types/models';
import ChatInterface from './components/ChatInterface';
import BasketSummary from './components/BasketSummary';

const App: React.FC = () => {
    const [sessionId, setSessionId] = useState<string | null>(null);
    const [basket, setBasket] = useState<Basket | null>(null);
    const [isLoadingBasket, setIsLoadingBasket] = useState<boolean>(false);

    // Initialize session on mount
    useEffect(() => {
        const session = getSessionId();
        setSessionId(session);
    }, []);

    // Fetch basket data
    const fetchBasket = async () => {
        if (!sessionId) return;

        setIsLoadingBasket(true);
        try {
            const basketData = await api.baskets.get();
            setBasket(basketData);
        } catch (error) {
            console.error('Error fetching basket:', error);
            // Initialize empty basket on error
            setBasket({
                session_id: sessionId,
                items: [],
                total: 0,
                item_count: 0,
            });
        } finally {
            setIsLoadingBasket(false);
        }
    };

    // Fetch basket when session is initialized
    useEffect(() => {
        if (sessionId) {
            fetchBasket();
        }
    }, [sessionId]);

    // Handler to refresh basket (called by child components)
    const handleBasketUpdate = () => {
        fetchBasket();
    };

    if (!sessionId) {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center">
                <div className="text-gray-600">Initializing session...</div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gray-50">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                <header className="mb-8">
                    <h1 className="text-3xl font-bold text-gray-900">
                        Conversational Checkout
                    </h1>
                    <p className="mt-2 text-sm text-gray-600">
                        Chat with our assistant to find products and complete your purchase
                    </p>
                </header>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    {/* Chat interface */}
                    <div className="lg:col-span-2">
                        <ChatInterface
                            sessionId={sessionId}
                            onBasketUpdate={handleBasketUpdate}
                        />
                    </div>

                    {/* Basket summary */}
                    <div className="lg:col-span-1">
                        <BasketSummary
                            basket={basket}
                            isLoading={isLoadingBasket}
                            onBasketUpdate={handleBasketUpdate}
                        />
                    </div>
                </div>
            </div>
        </div>
    );
};

export default App;
