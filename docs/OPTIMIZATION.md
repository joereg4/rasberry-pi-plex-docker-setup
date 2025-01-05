# Video Optimization Guide

## Quality Settings
- CRF 18: High quality, larger files
- CRF 23: Good balance
- CRF 28: Smaller files, acceptable quality

## Commands
1. **Single File**:
   ```bash
   ./scripts/optimize_local.sh -i input.mp4 -o output.mp4 -q 18
   ```

2. **Batch Processing**:
   ```bash
   ./scripts/batch_optimize_local.sh -s /path/to/movies -d /path/to/output -q 18
   ```

3. **Server Processing**:
   ```bash
   ./scripts/optimize_media.sh /path/to/media 18
   ``` 