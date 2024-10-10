// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "lib/forge-std/src/Test.sol";
import "../src/TokenB.sol";

contract TokenBTest is Test {
    TokenB tokenB;

    function setUp() public {
        // On déploie le contrat TokenB avec un montant initial de 1 000 tokens
        tokenB = new TokenB(1000 * 10 ** 18);
    }

    function testInitialSupply() public view {
        // Vérifie que le montant initial de tokens est attribué correctement au créateur du contrat
        assertEq(tokenB.totalSupply(), 1000 * 10 ** 18);
        assertEq(tokenB.balanceOf(address(this)), 1000 * 10 ** 18);
    }

    function testTokenNameAndSymbol() public view {
        // Vérifie le nom et le symbole du token
        assertEq(tokenB.name(), "Token B");
        assertEq(tokenB.symbol(), "TKNB");
    }

    function testTransfer() public {
        // Teste un transfert de tokens vers une adresse spécifique
        address recipient = address(0xBEEF);
        tokenB.transfer(recipient, 100 * 10 ** 18);

        assertEq(tokenB.balanceOf(recipient), 100 * 10 ** 18);
        assertEq(tokenB.balanceOf(address(this)), 900 * 10 ** 18);
    }
}
