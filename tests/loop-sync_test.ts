import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous test cases...]

Clarinet.test({
  name: "Ensure contract pause functionality works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    // Test pausing
    let pauseBlock = chain.mineBlock([
      Tx.contractCall(
        "loop-sync",
        "toggle-contract-pause",
        [],
        deployer.address
      )
    ]);
    
    assertEquals(pauseBlock.receipts[0].result, '(ok true)');

    // Try to register asset while paused
    let registerBlock = chain.mineBlock([
      Tx.contractCall(
        "loop-sync",
        "register-asset",
        [types.uint(1), types.utf8("Test"), types.uint(1)],
        deployer.address
      )
    ]);
    
    assertEquals(registerBlock.receipts[0].result, '(err u106)');
  }
});

// [Additional test cases for new functionality...]
