# Orderbook Smart Contract

## Description

Ce projet est un smart contract d'orderbook permettant aux utilisateurs d'échanger deux tokens ERC20 (TokenA et TokenB). Les utilisateurs peuvent placer des ordres d'achat et de vente, ainsi que les annuler, tout en s'assurant que les conditions de marché sont respectées.

## Fonctionnalités

- **Placer des ordres d'achat et de vente** : Les utilisateurs peuvent spécifier la quantité et le prix de leurs ordres.
- **Annuler des ordres** : Les utilisateurs peuvent annuler leurs ordres actifs.
- **Appariement d'ordres** : Les ordres d'achat et de vente peuvent être appariés automatiquement, en transférant les tokens appropriés entre les utilisateurs.
- **Vérifications des erreurs** : Le smart contract inclut des vérifications pour garantir que les ordres ne sont pas exécutés dans des conditions non valides (ex. : montant nul, prix invalide, autorisations insuffisantes).

## Prérequis

- [Foundry](https://book.getfoundry.sh/) pour la compilation et les tests des smart contracts
- Solidity version 0.8.28

## Installation

Clonez ce dépôt et installez Foundry :

```bash
git clone <URL_DU_DEPOT>
cd orderbook-project
foundryup

## Installation
