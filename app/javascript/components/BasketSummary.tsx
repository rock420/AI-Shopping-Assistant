import React, { useState } from 'react';
import BasketItem from './BasketItem';
import OrderPayment from './OrderPayment';
import OrderConfirmation from './OrderConfirmation';
import Modal from './Modal';
import api from '../utils/api';
import type { Basket, Order } from '../types/models';

interface BasketSummaryProps {
    basket: Basket | null;
    isLoading: boolean;
    onBasketUpdate: () => void;
}

const BasketSummary: React.FC<BasketSummaryProps> = ({ basket, isLoading, onBasketUpdate }) => {
    const [isCheckingOut, setIsCheckingOut] = useState(false);
    const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
    const [isConfirmationModalOpen, setIsConfirmationModalOpen] = useState(false);
    const [currentOrder, setCurrentOrder] = useState<Order | null>(null);
    const [checkoutError, setCheckoutError] = useState<string | null>(null);

    const handleCheckout = async () => {
        setIsCheckingOut(true);
        setCheckoutError(null);

        try {
            // Create order from basket
            const order = await api.orders.create();
            setCurrentOrder(order);
            setIsPaymentModalOpen(true);
        } catch (error: any) {
            console.error('Checkout error:', error);
            setCheckoutError(error.message || 'Failed to create order. Please try again.');
        } finally {
            setIsCheckingOut(false);
        }
    };

    const handlePaymentSuccess = (paymentId: string) => {
        console.log('Payment successful:', paymentId);
        setIsPaymentModalOpen(false);
        setIsConfirmationModalOpen(true);
    };

    const handlePaymentFailure = (error: string) => {
        console.error('Payment failed:', error);
        setIsPaymentModalOpen(false);
        setCheckoutError('Payment failed. Please try again.');
    };

    const handleConfirmationClose = () => {
        setIsConfirmationModalOpen(false);
        setCurrentOrder(null);
        onBasketUpdate();
    };
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

            {/* Error Message */}
            {checkoutError && (
                <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-md">
                    <p className="text-sm text-red-800">{checkoutError}</p>
                </div>
            )}

            {/* Checkout Button */}
            <div className="mt-6">
                <button
                    onClick={handleCheckout}
                    disabled={isCheckingOut}
                    className="w-full px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
                >
                    {isCheckingOut ? (
                        <>
                            <svg
                                className="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                                xmlns="http://www.w3.org/2000/svg"
                                fill="none"
                                viewBox="0 0 24 24"
                            >
                                <circle
                                    className="opacity-25"
                                    cx="12"
                                    cy="12"
                                    r="10"
                                    stroke="currentColor"
                                    strokeWidth="4"
                                />
                                <path
                                    className="opacity-75"
                                    fill="currentColor"
                                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                                />
                            </svg>
                            Creating Order...
                        </>
                    ) : (
                        'Proceed to Checkout'
                    )}
                </button>
            </div>

            {/* Payment Modal */}
            {currentOrder && (
                <Modal
                    isOpen={isPaymentModalOpen}
                    onClose={() => setIsPaymentModalOpen(false)}
                    title="Complete Payment"
                    size="lg"
                >
                    <OrderPayment
                        order={currentOrder}
                        onPaymentSuccess={handlePaymentSuccess}
                        onPaymentFailure={handlePaymentFailure}
                        onCancel={() => setIsPaymentModalOpen(false)}
                    />
                </Modal>
            )}

            {/* Order Confirmation Modal */}
            {currentOrder && (
                <Modal
                    isOpen={isConfirmationModalOpen}
                    onClose={handleConfirmationClose}
                    title="Order Confirmed"
                    size="md"
                >
                    <div className="space-y-4">
                        <OrderConfirmation order={currentOrder} />
                        <button
                            onClick={handleConfirmationClose}
                            className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors font-medium"
                        >
                            Continue Shopping
                        </button>
                    </div>
                </Modal>
            )}
        </div>
    );
};

export default BasketSummary;
