# Testing Checklist

## Environment Setup
- [ ] Container starts successfully
- [ ] Scripts are executable
- [ ] Environment variables persist
- [ ] Storage mounts are accessible

## Configuration Tests
- [ ] Plex claim token is set
- [ ] Timezone is configured correctly
- [ ] Email settings are correct
- [ ] Vultr settings are present (if configured)

## Storage Tests
- [ ] Check storage script runs
- [ ] Optimize media script runs
- [ ] Reports directory exists
- [ ] Permissions are correct

## Script Tests
- [ ] setup.sh completes without errors
- [ ] manage_storage.sh functions work
- [ ] check_storage.sh shows correct info
- [ ] optimize_media.sh can analyze files

## Clean Up
- [ ] Container can be stopped
- [ ] Environment can be cleaned
- [ ] No leftover files/volumes 