// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/console.sol";
import "../src/Orderbook.sol";
import "../src/TokenA.sol";
import "../src/TokenB.sol";

contract OrderbookTest is Test {
    Orderbook orderbook;
    TokenA tokenA;
    TokenB tokenB;
    address buyer;
    address seller;

    function setUp() public {
        // Initialisation des tokens avec un approvisionnement initial
        tokenA = new TokenA(1000 * 10 ** 18); 
        tokenB = new TokenB(1000 * 10 ** 18); 

        console.log("Initial TokenA balance of deployer:", tokenA.balanceOf(address(this)));
        console.log("Initial TokenB balance of deployer:", tokenB.balanceOf(address(this)));

        // Initialisation du contrat Orderbook
        orderbook = new Orderbook(address(tokenA), address(tokenB));

        // Définition des adresses de l'acheteur et du vendeur
        buyer = address(this);
        seller = address(0xBEEF);

        // Transférer 500 TokenA de l'adresse de déploiement vers le vendeur
        tokenA.transfer(seller, 500 * 10 ** 18); 

        // Vérification des soldes après transfert
        console.log("TokenA balance of seller after transfer:", tokenA.balanceOf(seller));
        console.log("TokenB balance of buyer (deployer) after initialization:", tokenB.balanceOf(buyer));

        // Vérification des soldes initiaux
        assertEq(tokenA.balanceOf(seller), 500 * 10 ** 18, "Seller does not have the correct initial amount of TokenA");
        assertEq(tokenB.balanceOf(buyer), 1000 * 10 ** 18, "Buyer does not have the correct initial amount of TokenB");
    }

    function testPlaceBuyOrder() public {
    // Approuver TokenB pour le contrat Orderbook
    tokenB.approve(address(orderbook), 100 * 10 ** 18);

    // Placer un ordre d'achat
    orderbook.placeOrder(50 * 10 ** 18, 10, true);

    // Vérifier que l'ordre d'achat est bien placé
    Orderbook.Order memory buyOrder = orderbook.getOrder(0);
    assertEq(buyOrder.amount, 50 * 10 ** 18, "Buy order amount is incorrect");
    assertEq(buyOrder.price, 10, "Buy order price is incorrect");
    assertEq(buyOrder.isBuyOrder, true, "Buy order type is incorrect");
}

function testPlaceSellOrder() public {
    // Simuler le vendeur et approuver TokenA pour le contrat Orderbook
    vm.startPrank(seller);
    tokenA.approve(address(orderbook), 50 * 10 ** 18);
    orderbook.placeOrder(50 * 10 ** 18, 10, false); // Placer un ordre de vente
    vm.stopPrank();

    // Vérifier que l'ordre de vente est bien placé
    Orderbook.Order memory sellOrder = orderbook.getOrder(0);
    assertEq(sellOrder.amount, 50 * 10 ** 18, "Sell order amount is incorrect");
    assertEq(sellOrder.price, 10, "Sell order price is incorrect");
    assertEq(sellOrder.isBuyOrder, false, "Sell order type is incorrect");
}

function testMatchOrders() public {
    // Approuver TokenA pour le vendeur et TokenB pour l'acheteur
    vm.startPrank(seller);
    tokenA.approve(address(orderbook), 50 * 10 ** 18); 
    vm.stopPrank();

    tokenB.approve(address(orderbook), 500 * 10 ** 18); 

    // Placer un ordre d'achat et un ordre de vente
    orderbook.placeOrder(50 * 10 ** 18, 10, true); 
    vm.startPrank(seller);
    orderbook.placeOrder(50 * 10 ** 18, 10, false); 
    vm.stopPrank();

    // Vérifier les soldes avant la correspondance
    uint256 initialBuyerTokenABalance = tokenA.balanceOf(address(this));
    uint256 initialSellerTokenBBalance = tokenB.balanceOf(seller);

    // Exécuter la correspondance des ordres
    orderbook.matchOrders();

    // Vérifier les soldes après la correspondance des ordres
    uint256 finalBuyerTokenABalance = tokenA.balanceOf(address(this));
    uint256 finalSellerTokenBBalance = tokenB.balanceOf(seller);

    assertEq(finalBuyerTokenABalance, initialBuyerTokenABalance + 50 * 10 ** 18, "Buyer did not receive the correct amount of TokenA");
    assertEq(finalSellerTokenBBalance, initialSellerTokenBBalance + 500 * 10 ** 18, "Seller did not receive the correct amount of TokenB");

    // Vérifier que les ordres ont été exécutés correctement
    Orderbook.Order memory remainingBuyOrder = orderbook.getOrder(0);
    Orderbook.Order memory remainingSellOrder = orderbook.getOrder(1);

    assertEq(remainingBuyOrder.amount, 0, "Buy order was not fully executed");
    assertEq(remainingSellOrder.amount, 0, "Sell order was not fully executed");
}

function testPlaceOrderWithZeroAmount() public {
    try orderbook.placeOrder(0, 10, true) {
        fail(); 
    } catch Error(string memory reason) {
        assertEq(reason, "Amount must be greater than 0");
    }
}

function testPlaceOrderWithZeroPrice() public {
    try orderbook.placeOrder(10 * 10 ** 18, 0, true) {
        fail(); 
    } catch Error(string memory reason) {
        assertEq(reason, "Price must be greater than 0");
    }
}


function testPartialOrderMatching() public {
    vm.startPrank(seller);
    tokenA.approve(address(orderbook), 30 * 10 ** 18); 
    orderbook.placeOrder(30 * 10 ** 18, 10, false); 
    vm.stopPrank();

    tokenB.approve(address(orderbook), 500 * 10 ** 18); 
    orderbook.placeOrder(50 * 10 ** 18, 10, true); 

    orderbook.matchOrders();

    Orderbook.Order memory remainingBuyOrder = orderbook.getOrder(1);
    assertEq(remainingBuyOrder.amount, 20 * 10 ** 18, "Buy order should have 20 TokenA remaining");
}
function testInsufficientAllowanceForTokenA() public {
    vm.startPrank(seller);
    tokenA.approve(address(orderbook), 10 * 10 ** 18); 
    orderbook.placeOrder(50 * 10 ** 18, 10, false); 

    tokenB.approve(address(orderbook), 500 * 10 ** 18); 
    orderbook.placeOrder(50 * 10 ** 18, 10, true); 

    try orderbook.matchOrders() {
        fail(); 
    } catch Error(string memory reason) {
        assertEq(reason, "Insufficient allowance for TokenA", "Expected insufficient allowance error");
    }
}

function testInsufficientAllowanceForTokenB() public {
    vm.startPrank(seller);
    tokenA.approve(address(orderbook), 50 * 10 ** 18); 
    orderbook.placeOrder(50 * 10 ** 18, 10, false); 
    vm.stopPrank();

    tokenB.approve(address(orderbook), 100 * 10 ** 18); 
    orderbook.placeOrder(50 * 10 ** 18, 10, true); 

    try orderbook.matchOrders() {
        fail(); 
    } catch Error(string memory reason) {
        assertEq(reason, "Insufficient allowance for TokenB", "Expected insufficient allowance error for TokenB");
    }
}


function testUnmatchableOrderDueToPrice() public {
    vm.startPrank(seller);
    tokenA.approve(address(orderbook), 50 * 10 ** 18); 
    orderbook.placeOrder(50 * 10 ** 18, 15, false); 
    vm.stopPrank();

    tokenB.approve(address(orderbook), 500 * 10 ** 18); 
    orderbook.placeOrder(50 * 10 ** 18, 10, true); 

    orderbook.matchOrders();

    Orderbook.Order memory buyOrder = orderbook.getOrder(1);
    Orderbook.Order memory sellOrder = orderbook.getOrder(0);
    assertEq(buyOrder.amount, 50 * 10 ** 18, "Buy order should remain unfilled");
    assertEq(sellOrder.amount, 50 * 10 ** 18, "Sell order should remain unfilled");
}

function testIgnoreOrdersBasedOnPriceMismatch() public {
    vm.startPrank(seller);
    tokenA.approve(address(orderbook), 50 * 10 ** 18); 
    orderbook.placeOrder(50 * 10 ** 18, 20, false); 
    vm.stopPrank();

    tokenB.approve(address(orderbook), 500 * 10 ** 18); 
    orderbook.placeOrder(50 * 10 ** 18, 10, true); 

    orderbook.matchOrders();

    Orderbook.Order memory buyOrder = orderbook.getOrder(1);
    Orderbook.Order memory sellOrder = orderbook.getOrder(0);
    assertEq(buyOrder.amount, 50 * 10 ** 18, "Buy order should remain unfilled due to price mismatch");
    assertEq(sellOrder.amount, 50 * 10 ** 18, "Sell order should remain unfilled due to price mismatch");
}

function testIgnoreFullyFilledOrders() public {
    vm.startPrank(seller);
    tokenA.approve(address(orderbook), 50 * 10 ** 18);
    orderbook.placeOrder(50 * 10 ** 18, 10, false); 
    vm.stopPrank();

    tokenB.approve(address(orderbook), 500 * 10 ** 18); 
    orderbook.placeOrder(50 * 10 ** 18, 10, true); 

    orderbook.matchOrders();

    vm.startPrank(seller);
    tokenA.approve(address(orderbook), 30 * 10 ** 18);
    orderbook.placeOrder(30 * 10 ** 18, 15, false); 
    vm.stopPrank();

    Orderbook.Order memory oldBuyOrder = orderbook.getOrder(1); 
    Orderbook.Order memory newSellOrder = orderbook.getOrder(2);

    assertEq(oldBuyOrder.amount, 0, "Old buy order should be fully filled and have zero amount");
    assertEq(newSellOrder.amount, 30 * 10 ** 18, "New sell order should remain unfilled due to price mismatch");
}

function testCancelOrder() public {
    tokenB.approve(address(orderbook), 100 * 10 ** 18);

    orderbook.placeOrder(50 * 10 ** 18, 10, true);

    Orderbook.Order memory buyOrder = orderbook.getOrder(0);
    assertEq(buyOrder.isActive, true, "Buy order should be active before cancellation");

    orderbook.cancelOrder(0);

    buyOrder = orderbook.getOrder(0);
    assertEq(buyOrder.isActive, false, "Buy order should be cancelled");
}

function testCancelNonExistingOrder() public {
    try orderbook.cancelOrder(999) {
        fail(); 
    } catch Error(string memory reason) {
        assertEq(reason, "Invalid order ID", "Expected invalid order ID error");
    }
}

function testCancelOtherUsersOrder() public {
    tokenB.approve(address(orderbook), 100 * 10 ** 18);
    orderbook.placeOrder(50 * 10 ** 18, 10, true);

    address otherUser = address(0xBEEF);
    vm.startPrank(otherUser);
    try orderbook.cancelOrder(0) {
        fail(); 
    } catch Error(string memory reason) {
        assertEq(reason, "You can only cancel your own orders", "Expected ownership error");
    }
    vm.stopPrank();
}

}
