import Foundation
import vibe_app

do {
    let zkeyPath = "../../../test-vectors/circom/hashpreimage_final.zkey"

    // Prepare inputs: Poseidon(12345)
    var inputs = [String: [String]]()
    inputs["secret"] = ["12345"]
    inputs["challengeHash"] = ["4267533774488295900887461483015112262021273608761099826938271132511348470966"]
    let input_str: String = (try? JSONSerialization.data(withJSONObject: inputs, options: .prettyPrinted)).flatMap {
        String(data: $0, encoding: .utf8)
    } ?? ""

    // Expected outputs: just the challengeHash
    let outputs: [String] = ["4267533774488295900887461483015112262021273608761099826938271132511348470966"]

    // Generate Proof
    let generateProofResult = try generateCircomProof(
        zkeyPath: zkeyPath, circuitInputs: input_str, proofLib: ProofLib.arkworks)
    assert(!generateProofResult.proof.a.x.isEmpty, "Proof should not be empty")

    // Verify Proof
    assert(
        outputs == generateProofResult.inputs,
        "Circuit outputs mismatch the expected outputs")

    let isValid = try verifyCircomProof(zkeyPath: zkeyPath, proofResult: generateProofResult, proofLib: ProofLib.arkworks)
    assert(isValid, "Proof verification should succeed")

    assert(generateProofResult.proof.a.x.count > 0, "Proof should not be empty")
    assert(generateProofResult.inputs.count > 0, "Inputs should not be empty")

} catch let error as MoproError {
    print("MoproError: \(error)")
    throw error
} catch {
    print("Unexpected error: \(error)")
    throw error
}
