# Testing Guide

## Quick Start
```bash
# 1. Clean and start container
./manage_test.sh rebuild

# 2. Inside container, start services
service postfix start
service cron start

# 3. Run all tests
cd /plex-docker-setup
./scripts/run_tests.sh

# 4. Verify results
service postfix status
service cron status
tail -f /var/log/mail.log
crontab -l
ls -l test_data/Media/Movies/

# 5. Exit container
exit

# 6. Clean up (optional)
./manage_test.sh clean
```

## Expected Results
- Email service running
- Cron jobs configured
- Test media files created
- Storage monitoring active
- Mail logs showing activity

## Test Environment
### Test Management Commands
```bash
# Clean test environment
./manage_test.sh clean

# Start test container
./manage_test.sh start

# Clean and start fresh
./manage_test.sh rebuild
```

### Inside Test Container
Once the container is running:
```bash
# Run all tests
cd /plex-docker-setup
./scripts/run_tests.sh

# Or run individual components:
./scripts/setup_email.sh    # Test email
./scripts/setup_cron.sh     # Test cron jobs
./scripts/manage_storage.sh check  # Test storage
```

## Test Data
- Sample media files in `test_data/Media/Movies`
- Created automatically during tests
- Cleaned up with `./manage_test.sh clean`

## Test Scenarios

### 1. Email System
```bash
# Set up email
./scripts/setup_email.sh
```

### 2. Storage Monitoring
```bash
# Set up cron
./scripts/setup_cron.sh
```

### 3. Cleanup System
```bash
# Test cleanup
./scripts/cleanup.sh
```

### 4. Email Notifications
```bash
# Watch mail log
tail -f /var/log/mail.log
```

## Verification Steps
### Service Status
```bash
# Check postfix
service postfix status

# Check cron
service cron status
```

### Log Files
```bash
# Check mail log
tail -n 20 /var/log/mail.log

# Check cron jobs
crontab -l

# Check storage status
df -h
```

## Troubleshooting
- If services fail to start, use `service <service> start`
- Check `/var/log/mail.log` for email issues
- Verify `.env` file exists and has correct permissions
- Use `docker logs` to check container issues 