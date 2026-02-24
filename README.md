# ZK Hash Preimage Demo

A Flutter mobile app that generates and verifies zero-knowledge proofs for Poseidon hash preimages, powered by [mopro](https://zkmopro.org).

<p align="center">
  <img src="screenshots/demo.png" alt="App screenshot" width="300" />
</p>

## What It Does

Prove you know a secret number that hashes to a given Poseidon hash -- without revealing the secret. The app simulates a challenge-response protocol:

1. Enter a secret number (private input)
2. A server provides a Poseidon hash challenge (public input)
3. Generate a Groth16 zero-knowledge proof on-device
4. Verify the proof locally

The secret never leaves the device. Only the proof is shared.

## Architecture

```
Flutter UI (Dart)
    |
    v
mopro Flutter bindings (flutter_rust_bridge)
    |
    v
Rust FFI (mopro-ffi + UniFFI)
    |
    v
circom-prover (Groth16 / Arkworks)
    |
    v
Poseidon hash preimage circuit (Circom)
```

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| [mopro-cli](https://zkmopro.org) | latest | `cargo install mopro-cli` |
| [Rust](https://rustup.rs) | stable | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| [Flutter SDK](https://flutter.dev) | 3.x | [flutter.dev/get-started](https://flutter.dev/docs/get-started/install) |
| [Node.js](https://nodejs.org) | 18+ | `brew install node` |
| Xcode (iOS) | 15+ | Mac App Store |

## Quick Start

```bash
# 1. Install circuit dependencies
cd circuits && npm install && cd ..

# 2. Initialize mopro adapters
mopro init

# 3. Build native bindings for Flutter
mopro build

# 4. Run the app
cd flutter
flutter pub get
flutter run
```

> After any Rust code changes, run `mopro build --auto-update` to regenerate bindings.

## Project Structure

```
vibe-app/
├── circuits/
│   └── hashpreimage.circom   # Poseidon hash preimage circuit
├── src/
│   └── lib.rs                # Rust core: proof generation & verification
├── flutter/
│   └── lib/main.dart         # Flutter UI
├── mopro_flutter_bindings/   # Generated Flutter plugin (flutter_rust_bridge)
├── test-vectors/             # Circuit zkey and test data
├── Config.toml               # mopro build configuration
├── Cargo.toml                # Rust dependencies
└── build.rs                  # Witness transpilation
```

## How the Demo Works

The circuit (`circuits/hashpreimage.circom`) is simple:

```circom
template HashPreimage() {
    signal input secret;           // private
    signal input challengeHash;    // public

    component hasher = Poseidon(1);
    hasher.inputs[0] <== secret;

    challengeHash === hasher.out;
}
```

The prover shows it knows `secret` such that `Poseidon(secret) == challengeHash`, without revealing `secret`. The app uses a precomputed lookup table of Poseidon hashes for the demo, but in production the challenge hash would come from a server.

Proof generation uses the **Arkworks** backend via `circom-prover`, producing a **Groth16** proof that can be verified in ~milliseconds.

## Learn More

- [mopro documentation](https://zkmopro.org)
- [mopro GitHub](https://github.com/zkmopro/mopro)
- [Circom language](https://docs.circom.io)
- [circomlib (Poseidon)](https://github.com/iden3/circomlib)
