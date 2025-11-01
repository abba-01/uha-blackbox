# UHA API Troubleshooting Guide

Common issues and solutions.

**Last Updated:** 2025-11-01

---

## Quick Diagnostics

```bash
# Test connectivity
curl https://got.gitgap.org/health/

# Test authentication
curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://got.gitgap.org/v1/uha/anchor

# Check IP whitelist status
curl https://got.gitgap.org/v1/uha/anchor
# If 403: IP not whitelisted
# If 401: Auth issue
```

---

## Authentication Issues

### Error: "Authentication credentials were not provided" (401)

**Cause:** Missing or malformed Authorization header

**Solution:**
```bash
# ❌ Wrong
curl https://got.gitgap.org/v1/uha/anchor

# ✅ Correct
curl -H "Authorization: Bearer uha.admin.YOUR_TOKEN" \
     https://got.gitgap.org/v1/uha/anchor
```

### Error: "Invalid or inactive token" (401)

**Causes:**
1. Token expired
2. Token revoked
3. Token typo

**Solutions:**
1. Request new token: Contact admin@got.gitgap.org
2. Check token hasn't been tombstoned
3. Verify token string is complete (no truncation)

---

## Rate Limiting

### Error: "Rate limit exceeded" (429)

**Tier 1 - Burst limit:**
- Limit: 1 request per second
- Solution: Add 1-second delay between requests

```python
import time
for coords in coordinate_list:
    result = client.encode(**coords)
    time.sleep(1.1)  # Wait 1.1 seconds
```

**Tier 2 - Daily quota:**
- Limit: 1000 requests per day
- Resets: Midnight UTC
- Solution: Wait until reset or contact admin for quota increase

**Check quota:**
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://got.gitgap.org/v1/admin/usage/your_observer
```

---

## IP Whitelisting

### Error: "Access denied: Source IP not in allowed VPC range" (403)

**Cause:** Your IP address is not whitelisted

**Solution:**
1. Find your IP: `curl ifconfig.me`
2. Email admin@got.gitgap.org with:
   - Your IP address
   - Observer name
   - Use case
3. Wait for whitelist approval

**Whitelisted ranges:**
- VPC: 10.124.0.0/20
- Specific IPs: Contact admin

---

## Connection Issues

### Connection Timeout

**Causes:**
1. Firewall blocking HTTPS
2. DNS resolution failure
3. Server downtime

**Diagnostics:**
```bash
# Test DNS
nslookup got.gitgap.org

# Test connectivity
ping got.gitgap.org

# Test HTTPS
curl -v https://got.gitgap.org/health/

# Check firewall
telnet got.gitgap.org 443
```

**Solutions:**
1. Allow outbound HTTPS (port 443)
2. Check corporate firewall/proxy settings
3. Verify DNS resolves to 143.244.211.53
4. Increase client timeout to 60 seconds

### SSL Certificate Error

**Error:** "SSL certificate problem: unable to get local issuer certificate"

**Cause:** Missing Let's Encrypt root certificate

**Solution:**
```bash
# Update CA certificates (Linux)
sudo update-ca-certificates

# Python
pip install --upgrade certifi

# PHP
# Update php.ini with current ca-bundle.crt path
```

---

## Data Format Issues

### Invalid Coordinates

**Error:** "Invalid request: coordinates out of range"

**Valid ranges:**
- RA: 0-360 degrees
- Dec: -90 to +90 degrees
- Distance: > 0 Mpc
- Resolution: 8-32 bits

**Example:**
```json
{
  "ra": 180.0,     // ✅ Valid (0-360)
  "dec": 45.0,     // ✅ Valid (-90 to 90)
  "distance": 100.0, // ✅ Valid (> 0)
  "resolution_bits": 16  // ✅ Valid (8-32)
}
```

### JSON Syntax Error

**Error:** "Expecting property name enclosed in double quotes"

**Cause:** Invalid JSON format

```json
❌ Wrong:
{ra: 180, dec: 45}  // Missing quotes

✅ Correct:
{"ra": 180.0, "dec": 45.0}
```

---

## Joomla-Specific Issues

### "Failed to load .env file"

**Cause:** Credentials file missing or wrong permissions

**Solution:**
```bash
# Check file exists
ls -la /home/yoursite/secure/.env

# Fix permissions
chmod 600 /home/yoursite/secure/.env
chown www-data:www-data /home/yoursite/secure/.env
```

### "Cannot connect to Django API"

**Diagnostics:**
```bash
# From Joomla server
curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://got.gitgap.org/v1/uha/anchor

# Check logs
tail -f /home/yoursite/public_html/logs/uha_debug.log
```

### "Token balance exhausted"

**Solution:**
1. Log into Joomla admin
2. Navigate to Components → UHA → Tokens
3. Click "Refill" and purchase more tokens

---

## Python Client Issues

### ImportError: "No module named 'uha_client'"

**Solution:**
```bash
# Install SDK
pip install uha-client

# Verify installation
python -c "import uha_client; print(uha_client.__version__)"
```

### "Connection pool is full"

**Cause:** Too many simultaneous connections

**Solution:**
```python
# Reuse client instance
client = UHAClient(token=token)

# Don't create new client for each request
# ❌ for i in range(1000): client = UHAClient(...)
# ✅ for i in range(1000): client.encode(...)
```

---

## Performance Issues

### Slow Response Times

**Expected latencies:**
- Health check: < 50ms
- Get anchor: < 100ms
- Encode/decode: < 200ms
- Multi-resolution: 1-5 seconds

**If slower:**
1. Check network latency: `ping got.gitgap.org`
2. Use CDN/caching for anchor (changes rarely)
3. Batch requests when possible
4. Contact admin if server-side issue

### High Memory Usage

**Cause:** Large batch operations

**Solution:**
```python
# ❌ Don't load all results at once
results = [client.encode(**c) for c in million_coords]

# ✅ Process in chunks
def process_in_chunks(coords, chunk_size=1000):
    for i in range(0, len(coords), chunk_size):
        chunk = coords[i:i+chunk_size]
        yield [client.encode(**c) for c in chunk]
```

---

## Error Reference

| Status | Error | Cause | Solution |
|--------|-------|-------|----------|
| 400 | Invalid request | Malformed JSON/params | Check request format |
| 401 | Not authenticated | Missing/invalid token | Add Authorization header |
| 403 | Access denied | IP not whitelisted | Contact admin |
| 404 | Not found | Wrong endpoint | Check API docs |
| 429 | Rate limit exceeded | Too many requests | Wait or increase quota |
| 500 | Server error | Internal error | Retry, then contact admin |
| 502 | Bad gateway | nginx/Django disconnect | Wait 30s, then retry |
| 503 | Service unavailable | Maintenance mode | Check status page |

---

## Getting Help

### 1. Check Status Page

https://status.got.gitgap.org (if available)

### 2. Review Logs

**Server logs (admin only):**
```bash
# Django errors
tail -f /opt/uha_service/logs/error.log

# nginx errors
tail -f /var/log/nginx/uha_api_error.log

# Request logs
tail -f /opt/uha_service/logs/access.log
```

**Client logs:**
```python
import logging
logging.basicConfig(level=logging.DEBUG)

client = UHAClient(token=token, logger=logging.getLogger('uha'))
```

### 3. Test Endpoints

```bash
# Health (should always work)
curl https://got.gitgap.org/health/

# Anchor (tests auth + API)
curl -H "Authorization: Bearer TOKEN" \
     https://got.gitgap.org/v1/uha/anchor

# Encode (tests full stack)
curl -X POST https://got.gitgap.org/v1/uha/encode \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ra":180,"dec":45,"distance":100,"resolution_bits":16}'
```

### 4. Contact Support

**Email:** admin@got.gitgap.org

**Include:**
- Observer name
- Timestamp of error
- Full error message
- Request/response (sanitize tokens!)
- Client library version

**GitHub Issues:** https://github.com/abba-01/uha-blackbox/issues

---

## FAQs

**Q: How do I increase my rate limit?**
A: Email admin@got.gitgap.org with your use case and required quota.

**Q: Can I use UHA API from localhost?**
A: No, your production IP must be whitelisted. Contact admin.

**Q: How do I rotate my API token?**
A: POST to `/v1/admin/token/rotate` (coming soon) or request new token from admin.

**Q: Is there a test/sandbox environment?**
A: Not currently. Use health endpoint for connectivity tests.

**Q: What's the SLA/uptime guarantee?**
A: Target 99.9% uptime. Check status page for current status.

**Q: Can I cache anchor responses?**
A: Yes! Anchor changes rarely (monthly at most). Cache for 24 hours.

**Q: What happens when I hit rate limit?**
A: 429 response. Retry-After header tells you when to retry. Quota resets at midnight UTC.

---

**Version:** 1.0.0
**Last Updated:** 2025-11-01
**Need more help?** admin@got.gitgap.org
