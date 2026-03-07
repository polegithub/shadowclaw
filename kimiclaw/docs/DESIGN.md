# KimiClaw Design Document

## Architecture

KimiClaw uses a configuration-driven approach with a single-entry bash script.

### Core Components

1. **Snapshot Generation**
   - SHA256 hash-based incremental backup
   - Deep desensitization (28+ JSON fields, 10+ value patterns)
   - Size-limited file filtering

2. **Manifest System**
   - JSON-based manifest with SHA256 hashes
   - Version tracking
   - File integrity verification

3. **Recovery System**
   - Automatic backup before restore
   - Idempotent operations
   - Credential auto-fill

### Security

- AES-256 encryption ready
- 40+ sensitive field patterns
- PEM private key detection
- Pre-push security scanning

### Performance

- Incremental backup saves 90%+ time
- Zstd compression support
- Parallel file processing capable

## Testing

Run `kimiclaw test` for self-test suite.
