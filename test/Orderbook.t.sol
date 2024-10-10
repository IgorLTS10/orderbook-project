// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "lib/forge-std/src/Test.sol";
import "../src/Orderbook.sol";
import "../src/TokenA.sol";
import "../src/TokenB.sol";

contract OrderbookTest is Test {
    Orderbook orderbook;
    TokenA tokenA;
    TokenB tokenB;

    function setUp() public {
        // Déploiement des tokens et de l'Orderbook
        tokenA = new TokenA(1000 * 10 ** 18);
        tokenB = new TokenB(1000 * 10 ** 18);
        orderbook = new Orderbook(address(tokenA), address(tokenB));
    }

    function testPlaceBuyOrder() public {
        orderbook.placeOrder(100 * 10 ** 18, 50, true);
        Orderbook.Order memory order = orderbook.getOrder(0);

        assertEq(order.user, address(this));
        assertEq(order.amount, 100 * 10 ** 18);
        assertEq(order.price, 50);
        assertEq(order.isBuyOrder, true);
    }

    function testPlaceSellOrder() public {
        orderbook.placeOrder(200 * 10 ** 18, 75, false);
        Orderbook.Order memory order = orderbook.getOrder(0);

        assertEq(order.user, address(this));
        assertEq(order.amount, 200 * 10 ** 18);
        assertEq(order.price, 75);
        assertEq(order.isBuyOrder, false);
    }
}
