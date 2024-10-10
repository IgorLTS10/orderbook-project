// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./TokenA.sol";
import "./TokenB.sol";

contract Orderbook {
    struct Order {
        address user;
        uint256 amount;
        uint256 price;
        bool isBuyOrder;
    }

    TokenA public tokenA;
    TokenB public tokenB;
    Order[] public orders;

    constructor(address _tokenA, address _tokenB) {
        tokenA = TokenA(_tokenA);
        tokenB = TokenB(_tokenB);
    }

    function placeOrder(uint256 amount, uint256 price, bool isBuyOrder) public {
        require(amount > 0, "Amount must be greater than 0");
        require(price > 0, "Price must be greater than 0");

        orders.push(Order(msg.sender, amount, price, isBuyOrder));
    }

    function getOrder(uint256 orderId) public view returns (Order memory) {
        require(orderId < orders.length, "Invalid order ID");
        return orders[orderId];
    }
}
