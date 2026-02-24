import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mopro_flutter_bindings/src/rust/third_party/vibe_app.dart';
import 'package:mopro_flutter_bindings/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZK Hash Preimage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const HashPreimageScreen(),
    );
  }
}

class HashPreimageScreen extends StatefulWidget {
  const HashPreimageScreen({super.key});

  @override
  State<HashPreimageScreen> createState() => _HashPreimageScreenState();
}

class _HashPreimageScreenState extends State<HashPreimageScreen> {
  final TextEditingController _secretController = TextEditingController();

  // Precomputed Poseidon hashes (computed via circomlibjs)
  static const Map<String, String> _poseidonHashes = {
    "1":
        "18586133768512220936620570745912940619677854269274689475585506675881198879027",
    "2":
        "8645981980787649023086883978738420856660271013038108762834452721572614684349",
    "3":
        "6018413527099068561047958932369318610297162528491556075919075208700178480084",
    "42":
        "12326503012965816391338144612242952408728683609716147019497703475006801258307",
    "100":
        "8540862089960479027598468084103001504332093299703848384261193335348282518119",
    "12345":
        "4267533774488295900887461483015112262021273608761099826938271132511348470966",
    "999999":
        "21684337208779804888941250689604787706765813346243268687471433053195528470185",
  };

  String? _challengeHash;
  CircomProofResult? _proofResult;
  bool? _verificationResult;
  bool _isProving = false;
  bool _isVerifying = false;
  Duration? _provingTime;
  Duration? _verifyingTime;
  String? _error;

  @override
  void initState() {
    super.initState();
    _secretController.text = "12345";
  }

  @override
  void dispose() {
    _secretController.dispose();
    super.dispose();
  }

  void _simulateChallenge() {
    final secret = _secretController.text.trim();
    final hash = _poseidonHashes[secret];
    setState(() {
      _error = null;
      _proofResult = null;
      _verificationResult = null;
      _provingTime = null;
      _verifyingTime = null;
      if (hash != null) {
        _challengeHash = hash;
      } else {
        _challengeHash = null;
        _error =
            'No precomputed hash for "$secret". Try: ${_poseidonHashes.keys.join(", ")}';
      }
    });
  }

  Future<void> _generateProof() async {
    if (_challengeHash == null) return;

    setState(() {
      _isProving = true;
      _error = null;
      _proofResult = null;
      _verificationResult = null;
      _verifyingTime = null;
    });

    FocusManager.instance.primaryFocus?.unfocus();
    final stopwatch = Stopwatch()..start();

    try {
      final inputs =
          '{"secret":["${_secretController.text.trim()}"],"challengeHash":["$_challengeHash"]}';
      final zkeyPath =
          await copyAssetToFileSystem('assets/hashpreimage_final.zkey');
      final result = await generateCircomProof(
        zkeyPath: zkeyPath,
        circuitInputs: inputs,
        proofLib: ProofLib.arkworks,
      );
      stopwatch.stop();

      if (!mounted) return;
      setState(() {
        _proofResult = result;
        _provingTime = stopwatch.elapsed;
        _isProving = false;
      });
    } catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _error = 'Proof generation failed: $e';
        _isProving = false;
      });
    }
  }

  Future<void> _verifyProof() async {
    if (_proofResult == null) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      final zkeyPath =
          await copyAssetToFileSystem('assets/hashpreimage_final.zkey');
      final valid = await verifyCircomProof(
        zkeyPath: zkeyPath,
        proofResult: _proofResult!,
        proofLib: ProofLib.arkworks,
      );
      stopwatch.stop();

      if (!mounted) return;
      setState(() {
        _verificationResult = valid;
        _verifyingTime = stopwatch.elapsed;
        _isVerifying = false;
      });
    } catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _error = 'Verification failed: $e';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZK Hash Preimage'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Poseidon Hash Preimage Proof',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prove you know a secret that hashes to a given value -- without revealing the secret. '
                      'The server provides a Poseidon hash challenge, and you generate a zero-knowledge proof.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Secret input
            TextField(
              controller: _secretController,
              decoration: const InputDecoration(
                labelText: 'Secret (private input)',
                hintText: 'Enter a number, e.g. 12345',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            // Simulate Server Challenge button
            FilledButton.tonal(
              onPressed:
                  (_isProving || _isVerifying) ? null : _simulateChallenge,
              child: const Text('Simulate Server Challenge'),
            ),
            const SizedBox(height: 16),

            // Challenge hash display
            if (_challengeHash != null)
              Card(
                color: theme.colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Challenge Hash (public)',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _challengeHash!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Generate / Verify buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: (_challengeHash != null &&
                            !_isProving &&
                            !_isVerifying)
                        ? _generateProof
                        : null,
                    child: _isProving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Generate Proof'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: (_proofResult != null &&
                            !_isProving &&
                            !_isVerifying)
                        ? _verifyProof
                        : null,
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Verify Proof'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Error display
            if (_error != null)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),

            // Results card
            if (_proofResult != null)
              Card(
                color: theme.colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Results',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_provingTime != null)
                        _resultRow(
                          'Proving time',
                          '${_provingTime!.inMilliseconds} ms',
                          theme,
                        ),
                      if (_verificationResult != null) ...[
                        _resultRow(
                          'Verification',
                          _verificationResult! ? 'VALID' : 'INVALID',
                          theme,
                          valueColor: _verificationResult!
                              ? Colors.green
                              : Colors.red,
                        ),
                        if (_verifyingTime != null)
                          _resultRow(
                            'Verify time',
                            '${_verifyingTime!.inMilliseconds} ms',
                            theme,
                          ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Public Inputs',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (final input in _proofResult!.inputs)
                        Text(
                          input,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      const SizedBox(height: 8),
                      ExpansionTile(
                        title: Text(
                          'Proof Data',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'A: (${_proofResult!.proof.a.x.substring(0, 20)}...)\n'
                              'B: (${_proofResult!.proof.b.x[0].substring(0, 20)}...)\n'
                              'C: (${_proofResult!.proof.c.x.substring(0, 20)}...)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, ThemeData theme,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Copies an asset to a file and returns the file path
Future<String> copyAssetToFileSystem(String assetPath) async {
  final byteData = await rootBundle.load(assetPath);
  final directory = await getApplicationDocumentsDirectory();
  final filename = assetPath.split('/').last;
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(byteData.buffer.asUint8List());
  return file.path;
}
