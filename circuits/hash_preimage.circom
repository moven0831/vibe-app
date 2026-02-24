pragma circom 2.0.0;

include "node_modules/circomlib/circuits/poseidon.circom";

template HashPreimage() {
    signal input secret;           // private
    signal input challengeHash;    // public

    component hasher = Poseidon(1);
    hasher.inputs[0] <== secret;

    challengeHash === hasher.out;
}

component main { public [challengeHash] } = HashPreimage();
