import React from 'react';
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

            <div className="space-y-3">
                {basket.items.map((item, index) => (
                    <div key={index} className="flex justify-between items-start pb-3 border-b border-gray-200">
                        <div className="flex-1">
                            <h3 className="text-sm font-medium text-gray-900">
                                {item.product_name}
                            </h3>
                            <p className="text-xs text-gray-500 mt-1">
                                Quantity: {item.quantity}
                            </p>
                            <p className="text-xs text-gray-500">
                                ${Number(item.price).toFixed(2)} each
                            </p>
                        </div>
                        <div className="text-right">
                            <p className="text-sm font-semibold text-gray-900">
                                ${Number(item.line_total).toFixed(2)}
                            </p>
                        </div>
                    </div>
                ))}
            </div>

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

            <div className="mt-6">
                <button
                    onClick={() => {/* Checkout will be implemented in later tasks */ }}
                    className="w-full px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 transition-colors"
                >
                    Proceed to Checkout
                </button>
            </div>
        </div>
    );
};

export default BasketSummary;
