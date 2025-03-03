import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures enhanced metadata validation works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    // Test invalid JSON metadata
    let invalidBlock = chain.mineBlock([
      Tx.contractCall(
        "loop-sync",
        "register-asset",
        [types.uint(1), types.utf8("invalid"), types.uint(1)],
        deployer.address
      )
    ]);
    
    assertEquals(invalidBlock.receipts[0].result, '(err u105)');

    // Test valid JSON metadata
    let validBlock = chain.mineBlock([
      Tx.contractCall(
        "loop-sync",
        "register-asset",
        [types.uint(1), types.utf8('{"name": "Test"}'), types.uint(1)],
        deployer.address
      )
    ]);
    
    assertEquals(validBlock.receipts[0].result.startsWith('(ok'), true);
  }
});

Clarinet.test({
  name: "Ensures rate limiting works with configuration",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    // Set rate limit window
    let configBlock = chain.mineBlock([
      Tx.contractCall(
        "loop-sync",
        "set-rate-limit-window",
        [types.uint(100)],
        deployer.address
      )
    ]);
    
    assertEquals(configBlock.receipts[0].result, '(ok true)');
  }
});
