import uniffi.vibe_app.*

try {
    var zkeyPath = "./test-vectors/circom/hashpreimage_final.zkey"

    val input_str: String = "{\"secret\":[\"12345\"],\"challengeHash\":[\"4267533774488295900887461483015112262021273608761099826938271132511348470966\"]}"

    // Generate proof
    var generateProofResult = generateCircomProof(zkeyPath, input_str, ProofLib.ARKWORKS)

    // Verify proof
    var isValid = verifyCircomProof(zkeyPath, generateProofResult, ProofLib.ARKWORKS)
    assert(isValid) { "Proof is invalid" }

    assert(generateProofResult.proof.a.x.isNotEmpty()) { "Proof is empty" }
    assert(generateProofResult.inputs.size > 0) { "Inputs are empty" }


} catch (e: Exception) {
    println(e)
    throw e
}
