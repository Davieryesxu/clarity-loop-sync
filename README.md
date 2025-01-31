# LoopSync

A Clarity smart contract system for syncing and managing tokenized assets across chains.

## Features
- Asset registration and verification
- Cross-chain asset syncing with status tracking
- Asset locking and unlocking
- Asset ownership tracking
- Sync status management (SYNCING, COMPLETED, FAILED)

## Getting Started
1. Clone the repository
2. Install dependencies with `clarinet install`
3. Run tests with `clarinet test`

## Usage
The main contract exposes the following functions:
- register-asset
- sync-asset
- update-sync-status
- lock-asset
- unlock-asset
- verify-ownership

See the contract documentation for detailed usage.

## Recent Enhancements
- Added sync status management functionality
- Improved status tracking with COMPLETED/FAILED states
- Added authorization checks for status updates
