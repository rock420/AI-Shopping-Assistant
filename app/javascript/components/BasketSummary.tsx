import React from 'react';
import BasketItem from './BasketItem';
import type { Basket } from '../types/models';

interface BasketSummaryProps {
    basket: Basket | null;
    isLoading: boolean;
    onBasketUpdate: () => void;
}

const BasketSummary: React.FC<BasketSummaryProps> = ({ basket, isLoading, onBasketUpdate }) => {
    if (isLoading) {
        return (
            <div className="bg-white rounded-lg shadow p-6">
                <h2 className="text-xl font-semibold mb-4">Your Basket</h2>
                <div className="flex items-center justify-center h-32">
                    <div className="text-gray-600">Loading basket...</div>
                </div>
            </div>
        );
    }

    if (!basket || basket.items.length === 0) {
        return (
            <div className="bg-white rounded-lg shadow p-6">
                <h2 className="text-xl font-semibold mb-4">Your Basket</h2>
                <div className="text-center py-8">
                    <svg
                        className="mx-auto h-12 w-12 text-gray-400"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth={2}
                            d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"
                        />
                    </svg>
                    <p className="mt-2 text-sm text-gray-600">Your basket is empty</p>
                    <p className="mt-1 text-xs text-gray-500">
                        Start shopping by asking the assistant to find products
                    </p>
                </div>
            </div>
        );
    }

    return (
        <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold mb-4">Your Basket</h2>

            {/* Basket Items */}
            <div className="space-y-3 mb-4">
                {basket.items.map((item) => (
                    <BasketItem
                        key={item.product_id}
                        item={item}
                        onUpdate={onBasketUpdate}
                    />
                ))}
            </div>

            {/* Total Section */}
            <div className="mt-4 pt-4 border-t-2 border-gray-300">
                <div className="flex justify-between items-center">
                    <span className="text-base font-semibold text-gray-900">Total</span>
                    <span className="text-lg font-bold text-gray-900">
                        ${Number(basket.total).toFixed(2)}
                    </span>
                </div>
                <p className="text-xs text-gray-500 mt-1">
                    {basket.item_count} {basket.item_count === 1 ? 'item' : 'items'}
                </p>
            </div>

            {/* Checkout Button */}
            <div className="mt-6">
                <button
                    onClick={() => {/* Checkout will be implemented in later tasks */ }}
                    className="w-full px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 transition-colors font-medium"
                >
                    Proceed to Checkout
                </button>
            </div>
        </div>
    );
};

export default BasketSummary;
