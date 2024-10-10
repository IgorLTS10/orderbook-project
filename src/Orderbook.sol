// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "lib/forge-std/src/console.sol";
import "./TokenA.sol";
import "./TokenB.sol";

contract Orderbook {
    struct Order {
        address user;
        uint256 amount;
        uint256 price;
        bool isBuyOrder; // true = buy order, false = sell order
        bool isActive; // true if the order is active, false if cancelled
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

        orders.push(Order(msg.sender, amount, price, isBuyOrder, true));
    }

    function matchOrders() public {
    uint256 i = 0;
    while (i < orders.length) {
        Order storage buyOrder = orders[i];

        // Vérifier que l'ordre actuel est un ordre d'achat valide
        if (!buyOrder.isBuyOrder || buyOrder.amount == 0) {
            i++;
            continue; // Passer à l'ordre suivant
        }

        uint256 j = 0;
        while (j < orders.length) {
            Order storage sellOrder = orders[j];

            // Vérifier que l'ordre actuel est un ordre de vente valide
            if (sellOrder.isBuyOrder || sellOrder.amount == 0 || sellOrder.price > buyOrder.price) {
                j++;
                continue; // Passer à l'ordre suivant
            }

            uint256 matchedAmount = buyOrder.amount < sellOrder.amount ? buyOrder.amount : sellOrder.amount;

            // Vérification des autorisations avant le transfert
            require(tokenA.allowance(sellOrder.user, address(this)) >= matchedAmount, "Insufficient allowance for TokenA");
            require(tokenB.allowance(buyOrder.user, address(this)) >= matchedAmount * sellOrder.price, "Insufficient allowance for TokenB");

            // Effectuer l'échange de tokens
            tokenA.transferFrom(sellOrder.user, buyOrder.user, matchedAmount); // Transfert de TokenA du vendeur vers l'acheteur
            tokenB.transferFrom(buyOrder.user, sellOrder.user, matchedAmount * sellOrder.price); // Transfert de TokenB de l'acheteur vers le vendeur

            // Mise à jour des quantités des ordres
            buyOrder.amount -= matchedAmount;
            sellOrder.amount -= matchedAmount;

            // Supprimer les ordres exécutés
            if (buyOrder.amount == 0) {
                delete orders[i]; // Supprime complètement l'ordre d'achat s'il est exécuté
                break; // Sortir de la boucle interne car l'ordre d'achat est rempli
            }

            if (sellOrder.amount == 0) {
                delete orders[j]; // Supprime complètement l'ordre de vente s'il est exécuté
            }

            j++;
        }

        i++;
    }
}

    function cancelOrder(uint256 orderId) public {
        require(orderId < orders.length, "Invalid order ID");
        Order storage order = orders[orderId];
        require(order.user == msg.sender, "You can only cancel your own orders");
        require(order.isActive, "Order already cancelled");

        order.isActive = false; // Annuler l'ordre
    }

    function getOrder(uint256 orderId) public view returns (Order memory) {
        require(orderId < orders.length, "Invalid order ID");
        return orders[orderId];
    }
}
