import React, { useState } from 'react';
import { Product } from '../types/models';

interface ProductCardProps {
    product: Product;
    onAddToBasket?: (productId: number, quantity: number) => void;
    compact?: boolean;
}

const ProductCard: React.FC<ProductCardProps> = ({ product, onAddToBasket, compact = false }) => {
    const [isAdding, setIsAdding] = useState<boolean>(false);
    const [quantity, setQuantity] = useState<number>(1);

    const handleAddToBasket = async () => {
        if (!onAddToBasket || isAdding) return;

        setIsAdding(true);
        try {
            onAddToBasket(product.id, quantity);
            setQuantity(1);
        } catch (error) {
            console.error('Error adding to basket:', error);
        } finally {
            setIsAdding(false);
        }
    };

    const formatPrice = (price: number): string => {
        return `${Number(price).toFixed(2)}`;
    };

    const isOutOfStock = product.inventory_quantity === 0;
    const isLowStock = product.inventory_quantity > 0 && product.inventory_quantity <= 5;

    // Compact version for chat interface
    if (compact) {
        return (
            <div className="bg-white border border-gray-200 rounded-lg overflow-hidden flex flex-col sm:flex-row gap-3 p-3 hover:shadow-md transition-shadow w-full">
                {/* Compact Image */}
                <div className="bg-gray-100 w-full sm:w-20 h-32 sm:h-20 flex-shrink-0 rounded flex items-center justify-center">
                    {product.image_url ? (
                        <img
                            src={product.image_url}
                            alt={product.name}
                            className="w-full h-full object-cover rounded"
                        />
                    ) : (
                        <svg className="w-12 sm:w-8 h-12 sm:h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                        </svg>
                    )}
                </div>

                {/* Compact Details */}
                <div className="flex-1 min-w-0">
                    <h3 className="font-semibold text-gray-900 text-sm sm:truncate">{product.name}</h3>
                    <p className="text-xs text-gray-600 line-clamp-2 mt-1">{product.description}</p>

                    <div className="flex items-center justify-between mt-2 flex-wrap gap-2">
                        <span className="text-base sm:text-lg font-bold text-gray-900">${formatPrice(product.price)}</span>
                        <div className="text-xs">
                            {isOutOfStock ? (
                                <span className="text-red-600 font-medium">Out of Stock</span>
                            ) : isLowStock ? (
                                <span className="text-orange-600 font-medium">{product.inventory_quantity} left</span>
                            ) : (
                                <span className="text-green-600 font-medium">In Stock</span>
                            )}
                        </div>
                    </div>

                    {/* Compact Add to Basket */}
                    {!isOutOfStock && onAddToBasket && (
                        <div className="flex items-center gap-2 mt-2 flex-wrap sm:flex-nowrap">
                            <div className="flex items-center border border-gray-300 rounded">
                                <button
                                    onClick={() => setQuantity(Math.max(1, quantity - 1))}
                                    className="px-2 py-1 text-sm text-gray-600 hover:bg-gray-100"
                                    disabled={isAdding || quantity <= 1}
                                >
                                    −
                                </button>
                                <span className="px-2 py-1 text-sm border-x border-gray-300 min-w-[2rem] text-center">
                                    {quantity}
                                </span>
                                <button
                                    onClick={() => setQuantity(Math.min(product.inventory_quantity, quantity + 1))}
                                    className="px-2 py-1 text-sm text-gray-600 hover:bg-gray-100"
                                    disabled={isAdding || quantity >= product.inventory_quantity}
                                >
                                    +
                                </button>
                            </div>
                            <button
                                onClick={handleAddToBasket}
                                disabled={isAdding || isOutOfStock}
                                className="flex-1 sm:flex-initial bg-blue-600 text-white px-3 py-1 rounded text-xs hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors font-medium whitespace-nowrap"
                            >
                                {isAdding ? 'Adding...' : 'Add'}
                            </button>
                        </div>
                    )}
                </div>
            </div>
        );
    }

    // Full version
    return (
        <div className="bg-white border border-gray-200 rounded-lg shadow-sm hover:shadow-md transition-shadow duration-200 overflow-hidden flex flex-col">
            <div className="bg-gray-100 h-48 flex items-center justify-center">
                {product.image_url ? (
                    <img src={product.image_url} alt={product.name} className="w-full h-full object-cover" />
                ) : (
                    <svg className="w-16 h-16 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                )}
            </div>
            <div className="p-4 flex-1 flex flex-col">
                <h3 className="text-lg font-semibold text-gray-900 mb-1">{product.name}</h3>
                <p className="text-sm text-gray-600 mb-3 line-clamp-2 flex-1">{product.description}</p>
                <div className="mt-3 flex items-center justify-between">
                    <span className="text-xl font-bold text-gray-900">${formatPrice(product.price)}</span>
                    <div className="text-sm">
                        {isOutOfStock ? (
                            <span className="text-red-600 font-medium">Out of Stock</span>
                        ) : isLowStock ? (
                            <span className="text-orange-600 font-medium">Only {product.inventory_quantity} left</span>
                        ) : (
                            <span className="text-green-600 font-medium">In Stock</span>
                        )}
                    </div>
                </div>
                {!isOutOfStock && onAddToBasket && (
                    <div className="mt-4 flex items-center gap-2">
                        <div className="flex items-center border border-gray-300 rounded-md">
                            <button
                                onClick={() => setQuantity(Math.max(1, quantity - 1))}
                                className="px-3 py-1 text-gray-600 hover:bg-gray-100 transition-colors"
                                disabled={isAdding || quantity <= 1}
                            >
                                −
                            </button>
                            <input
                                type="number"
                                min="1"
                                max={product.inventory_quantity}
                                value={quantity}
                                onChange={(e) => {
                                    const val = parseInt(e.target.value) || 1;
                                    setQuantity(Math.min(Math.max(1, val), product.inventory_quantity));
                                }}
                                className="w-12 text-center border-x border-gray-300 py-1 focus:outline-none"
                                disabled={isAdding}
                            />
                            <button
                                onClick={() => setQuantity(Math.min(product.inventory_quantity, quantity + 1))}
                                className="px-3 py-1 text-gray-600 hover:bg-gray-100 transition-colors"
                                disabled={isAdding || quantity >= product.inventory_quantity}
                            >
                                +
                            </button>
                        </div>
                        <button
                            onClick={handleAddToBasket}
                            disabled={isAdding || isOutOfStock}
                            className="flex-1 bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors font-medium text-sm"
                        >
                            {isAdding ? 'Adding...' : 'Add to Basket'}
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
};

export default ProductCard;
