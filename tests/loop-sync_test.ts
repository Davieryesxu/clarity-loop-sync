import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can register new asset",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const assetId = 1;
    const metadata = "Test Asset";
    const chainId = 1;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "loop-sync",
        "register-asset",
        [types.uint(assetId), types.utf8(metadata), types.uint(chainId)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    assertEquals(block.receipts[0].result, '(ok true)');
  }
});

Clarinet.test({
  name: "Ensure only owner can register assets",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get("wallet_1")!;
    const assetId = 1;
    const metadata = "Test Asset";
    const chainId = 1;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "loop-sync",
        "register-asset",
        [types.uint(assetId), types.utf8(metadata), types.uint(chainId)],
        wallet1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(err u100)');
  }
});

Clarinet.test({
  name: "Ensure can sync asset",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const assetId = 1;
    const chainId = 2;
    
    // First register asset
    chain.mineBlock([
      Tx.contractCall(
        "loop-sync",
        "register-asset",
        [types.uint(assetId), types.utf8("Test"), types.uint(1)],
        deployer.address
      )
    ]);
    
    // Then sync
    let block = chain.mineBlock([
      Tx.contractCall(
        "loop-sync", 
        "sync-asset",
        [types.uint(assetId), types.uint(chainId)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(ok true)');
  }
});
