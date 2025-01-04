# Media Optimization Guide

## Local Optimization Tools

### Quick Start
```bash
# Make scripts executable
chmod +x scripts/batch_optimize_local.sh
chmod +x scripts/optimize_local.sh

# Analyze media without optimizing
./scripts/optimize_local.sh "/path/to/media"

# Batch optimize with default settings (CRF 18)
./scripts/batch_optimize_local.sh "/path/to/source" "/path/to/output"

# Batch optimize with custom CRF value
./scripts/batch_optimize_local.sh "/path/to/source" "/path/to/output" 23
```

### Quality Settings (CRF)
- **18-20**: High quality, larger files
  - Best for action/high-motion content
  - Recommended for archival purposes
- **21-23**: Balanced quality (recommended)
  - Good for most content
  - Significant size reduction
- **24-28**: Smaller files, good quality
  - Suitable for TV shows, documentaries
  - Maximum compression while maintaining quality

### Testing Process
1. **Analyze Current Media**:
   ```bash
   ./scripts/optimize_local.sh "/path/to/media"
   ```

2. **Test Single File**:
   ```bash
   # Test 5-minute segment
   ffmpeg -ss 00:00:00 -t 00:05:00 -i "input.mp4" -c:v libx264 -crf 23 -c:a copy "test_output.mp4"
   ```

3. **Batch Processing**:
   ```bash
   # Create output directory
   mkdir -p ~/Media/optimized

   # Run batch optimization
   ./scripts/batch_optimize_local.sh "~/Media/Movies" "~/Media/optimized" 23
   ```

### Best Practices
1. Always test with a single file first
2. Keep original files until quality is verified
3. Monitor disk space during batch operations
4. Start with CRF 23 and adjust based on results

### Storage Requirements
- Source directory needs read access
- Output directory needs write access
- Approximately 1x source size temporary space needed

### Quality Comparison
```bash
# Compare original and optimized files
./scripts/compare_quality.sh "original.mp4" "optimized.mp4"

# Install quality metrics tool (optional)
brew install ffmpeg_quality_metrics
```

#### Understanding Quality Metrics
- **VMAF Score**: 
  - 90-100: Excellent quality
  - 80-90: Good quality
  - 70-80: Fair quality
  - <70: Noticeable quality loss

- **Bitrate Reduction**:
  - 40-50%: Excellent optimization
  - 30-40%: Good optimization
  - 20-30%: Fair optimization
  - <20%: Minimal optimization

#### Visual Comparison Tips
1. Check dark scenes for banding
2. Look for detail in fast motion
3. Compare text clarity
4. Examine color gradients

### Troubleshooting
- If ffmpeg is missing: `brew install ffmpeg`
- For permission issues: `chmod +x scripts/*.sh`
- For space issues: Use `df -h` to check available space 