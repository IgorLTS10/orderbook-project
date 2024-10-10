// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../src/TokenA.sol";

contract TokenATest is Test {
    TokenA tokenA;

    function setUp() public {
        // On déploie le contrat TokenA avec un montant initial de 1 000 tokens
        tokenA = new TokenA(1000 * 10 ** 18);
    }

    function testInitialSupply() public view {
        // Vérifie que le montant initial de tokens est attribué correctement au créateur du contrat
        assertEq(tokenA.totalSupply(), 1000 * 10 ** 18);
        assertEq(tokenA.balanceOf(address(this)), 1000 * 10 ** 18);
    }

    function testTokenNameAndSymbol() public view{
        // Vérifie le nom et le symbole du token
        assertEq(tokenA.name(), "Token A");
        assertEq(tokenA.symbol(), "TKNA");
    }

    function testTransfer() public {
        // Teste un transfert de tokens vers une adresse spécifique
        address recipient = address(0xBEEF);
        tokenA.transfer(recipient, 100 * 10 ** 18);

        assertEq(tokenA.balanceOf(recipient), 100 * 10 ** 18);
        assertEq(tokenA.balanceOf(address(this)), 900 * 10 ** 18);
    }
}
