# FlashLoan Arbitrage Contract

## Overview

This Solidity contract facilitates flash loan-based triangular arbitrage on the Ethereum blockchain. It's designed to leverage price differences between assets on PancakeSwap, aiming to generate profits through successive trades within a single transaction block.

## Contract Functionality

### `initateArbitrage`

- **Description:** Initiates the arbitrage.
- **Parameters:**
  - `busdBorrow`: Address of the borrowed BUSD token.
  - `amount`: Amount of BUSD to borrow for the arbitrage.
- **Actions:**
  - Approves BUSD, CROX, and CAKE token spending on the PancakeSwap Router.
  - initiating the arbitrage process.

### `pancakeCall`

- **Description:** Executes the arbitrage steps and handles repayment to the flash loan pool.
- **Parameters:**
  - `sender`: Address initiating the call.
  - `amount0`: Amount of the first token in the pair.
  - `amount1`: Amount of the second token in the pair.
  - `data`: Encoded data containing details for the arbitrage.
- **Actions:**
  - Checks and validates the sender and contract alignment.
  - Decodes the data to retrieve loan details (borrowed token, amount, borrower's address).
  - Executes the series of trades for triangular arbitrage (BUSD → CROX → CAKE → BUSD).
  - Verifies the profitability of the arbitrage.
  - Transfers profits to the initiator and repays the flash loan.

### Other Functions

- `getBalanceOfToken`: Retrieves the contract's balance of a specific token.
- `placeTrade`: Executes token swaps through PancakeSwap based on specified tokens and amounts.
- `checkProfit`: Helper function to check if the arbitrage yields profits.

### Prerequisites

- Ensure you have a development environment.

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/M-hassan-ch/FlashLoan-DEFI.git
   ```

2. Navigate to the project directory:
   ```
   cd FlashLoan-DEFI
   ```

3. Install dependencies:
   ```
   npm install
   ```

### Usage
1. Run the FlashLoan application doing:
   ```
   npm test
   ```

## Usage

1. Deploy the contract on the Ethereum blockchain.
2. Call `initateArbitrage` with the desired parameters to start the arbitrage process.
3. The contract will autonomously execute trades and handle repayments.
4. Ensure sufficient liquidity and price differences to yield profitable arbitrage.
5. If you get an error "PancakeCall: Arbitrage is not profitable" then find crypto pairs and replace them in the contract which can provide you with profitable arbitrage.
