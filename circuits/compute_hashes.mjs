import { buildPoseidon } from "circomlibjs";

async function main() {
    const poseidon = await buildPoseidon();

    // Test values - compute Poseidon(secret) for each
    const secrets = [1, 2, 3, 42, 100, 12345, 999999];

    console.log("// Precomputed Poseidon hashes for test values");
    console.log("// Format: secret -> Poseidon(secret) as decimal string");
    console.log("");

    for (const secret of secrets) {
        const hash = poseidon([secret]);
        const hashStr = poseidon.F.toString(hash, 10);
        console.log(`secret: ${secret}`);
        console.log(`  hash: ${hashStr}`);
        console.log("");
    }

    // Also output as JSON for easy copy into Dart
    console.log("// JSON lookup table for Dart:");
    const lookup = {};
    for (const secret of secrets) {
        const hash = poseidon([secret]);
        lookup[secret.toString()] = poseidon.F.toString(hash, 10);
    }
    console.log(JSON.stringify(lookup, null, 2));

    // Verify one value with snarkjs fullprove format
    console.log("\n// Test input for snarkjs fullprove (secret=12345):");
    const testSecret = 12345;
    const testHash = poseidon([testSecret]);
    const testHashStr = poseidon.F.toString(testHash, 10);
    const input = { secret: testSecret.toString(), challengeHash: testHashStr };
    console.log(JSON.stringify(input));
}

main().catch(console.error);
