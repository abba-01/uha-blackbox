# UHA Integration Guide

Complete guide for integrating UHA API into your application.

**Last Updated:** 2025-11-01

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Python Integration](#python-integration)
3. [PHP Integration](#php-integration)
4. [Joomla Integration](#joomla-integration)
5. [JavaScript Integration](#javascript-integration)
6. [R Integration](#r-integration)

---

## Quick Start

### 1. Get API Token

Contact admin@got.gitgap.org to request a token, or use the public endpoint:

```bash
curl -X POST https://got.gitgap.org/api/request-token \
  -H "Content-Type: application/json" \
  -d '{"observer":"my_app","email":"you@example.com","use_case":"Research"}'
```

### 2. Test Connection

```bash
curl -H "Authorization: Bearer YOUR_TOKEN_HERE" \
     https://got.gitgap.org/v1/uha/anchor
```

### 3. Start Encoding

```bash
curl -X POST https://got.gitgap.org/v1/uha/encode \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"ra":180.0,"dec":45.0,"distance":100.0,"resolution_bits":16}'
```

---

## Python Integration

### Install SDK

```bash
pip install uha-client
```

### Basic Usage

```python
from uha_client import UHAClient

# Initialize client
client = UHAClient(
    base_url="https://got.gitgap.org/v1",
    token="uha.admin.YOUR_TOKEN_HERE"
)

# Get anchor
anchor = client.get_anchor()
print(f"Anchor version: {anchor['version']}")

# Encode coordinates
uha_address = client.encode(
    ra=180.0,
    dec=45.0,
    distance=100.0,
    resolution_bits=16
)
print(f"UHA Address: {uha_address}")

# Decode back
coords = client.decode(uha_address)
print(f"Coordinates: RA={coords['ra']}, Dec={coords['dec']}")
```

### Advanced Usage

```python
# Multi-resolution encoding
results = client.multiresolution_encode(
    ra=180.0,
    dec=45.0,
    distance=100.0,
    resolution_schedule=[8, 12, 16, 20, 24]
)

# Batch encoding
addresses = client.encode_batch([
    {"ra": 180.0, "dec": 45.0, "distance": 100.0},
    {"ra": 90.0, "dec": 30.0, "distance": 200.0},
    # ... up to 1000 at once
])

# Error handling
try:
    result = client.encode(ra=180.0, dec=45.0, distance=100.0)
except uha_client.RateLimitError as e:
    print(f"Rate limited. Retry after {e.retry_after} seconds")
except uha_client.AuthenticationError:
    print("Invalid token")
```

---

## PHP Integration

### Install via Composer

```bash
composer require uha/client
```

### Basic Usage

```php
<?php
require 'vendor/autoload.php';

use UHA\Client;

// Initialize
$client = new Client(
    baseUrl: 'https://got.gitgap.org/v1',
    token: 'uha.admin.YOUR_TOKEN_HERE'
);

// Get anchor
$anchor = $client->getAnchor();
echo "Anchor: " . $anchor['version'] . "\n";

// Encode
$address = $client->encode([
    'ra' => 180.0,
    'dec' => 45.0,
    'distance' => 100.0,
    'resolution_bits' => 16
]);
echo "UHA Address: $address\n";

// Decode
$coords = $client->decode($address);
echo "RA: {$coords['ra']}, Dec: {$coords['dec']}\n";
```

### Error Handling

```php
try {
    $address = $client->encode($params);
} catch (UHA\RateLimitException $e) {
    error_log("Rate limited: " . $e->getRetryAfter());
    sleep($e->getRetryAfter());
} catch (UHA\AuthenticationException $e) {
    error_log("Auth failed: " . $e->getMessage());
}
```

---

## Joomla Integration

### Install com_uha Component

1. Download from: https://github.com/abba-01/com_uha_joomla
2. Install via Joomla Extensions Manager
3. Configure in Components → UHA

### Configuration

**File:** `/home/yoursite/secure/.env`

```env
UHA_API_URL=https://got.gitgap.org/v1/
UHA_ADDRESS=uha://your_dataset_here
DJANGO_API_TOKEN=uha.admin.YOUR_TOKEN_HERE
UHA_LOG_REQUESTS=1
UHA_TIMEOUT=30
```

### Usage in Joomla

```php
<?php
// In your Joomla component/module/plugin

use Joomla\Component\Uha\Administrator\Service\DjangoApiClient;

// Initialize
$client = new DjangoApiClient(
    getenv('UHA_API_URL'),
    null,  // UHA address (optional)
    getenv('DJANGO_API_TOKEN')
);

// Get anchor
$anchor = $client->getAnchor();

// Encode
$result = $client->post('/uha/encode', [
    'ra' => 180.0,
    'dec' => 45.0,
    'distance' => 100.0,
    'resolution_bits' => 16
]);

echo $result['uha_address'];
```

### Token Management

```php
// Check token balance
$balance = $client->get('/admin/usage/your_observer');
echo "Requests remaining: " . ($balance['daily_limit'] - $balance['current_count']);

// Purchase more tokens (via admin panel)
// Navigate to: Components → UHA → Tokens → Refill
```

---

## JavaScript Integration

### Install via npm

```bash
npm install uha-client-js
```

### Browser Usage

```javascript
import { UHAClient } from 'uha-client-js';

// Initialize
const client = new UHAClient({
  baseUrl: 'https://got.gitgap.org/v1',
  token: 'uha.admin.YOUR_TOKEN_HERE'
});

// Get anchor
const anchor = await client.getAnchor();
console.log('Anchor:', anchor.version);

// Encode
const address = await client.encode({
  ra: 180.0,
  dec: 45.0,
  distance: 100.0,
  resolutionBits: 16
});
console.log('UHA Address:', address);

// Decode
const coords = await client.decode(address);
console.log('Coordinates:', coords);
```

### Node.js Usage

```javascript
const { UHAClient } = require('uha-client-js');

const client = new UHAClient({
  baseUrl: process.env.UHA_API_URL,
  token: process.env.UHA_API_TOKEN
});

// Async/await
async function encodeCoordinates() {
  try {
    const address = await client.encode({
      ra: 180.0,
      dec: 45.0,
      distance: 100.0
    });
    return address;
  } catch (error) {
    if (error.name === 'RateLimitError') {
      console.log(`Rate limited. Retry after ${error.retryAfter}s`);
    }
    throw error;
  }
}
```

---

## R Integration

### Install from CRAN

```r
install.packages("uha")
```

### Basic Usage

```r
library(uha)

# Initialize client
client <- uha_client(
  base_url = "https://got.gitgap.org/v1",
  token = Sys.getenv("UHA_API_TOKEN")
)

# Get anchor
anchor <- uha_get_anchor(client)
print(anchor$version)

# Encode coordinates
address <- uha_encode(
  client,
  ra = 180.0,
  dec = 45.0,
  distance = 100.0,
  resolution_bits = 16
)
print(address)

# Decode
coords <- uha_decode(client, address)
print(paste("RA:", coords$ra, "Dec:", coords$dec))
```

### Batch Processing

```r
# Encode data frame of coordinates
library(dplyr)

coordinates <- data.frame(
  ra = c(180.0, 90.0, 270.0),
  dec = c(45.0, 30.0, -15.0),
  distance = c(100.0, 200.0, 150.0)
)

# Encode all at once
addresses <- coordinates %>%
  rowwise() %>%
  mutate(uha_address = uha_encode(client, ra, dec, distance))

print(addresses)
```

---

## Best Practices

### 1. Token Security

❌ **Don't:**
```python
# Hard-coded tokens
client = UHAClient(token="uha.admin.abc123...")
```

✅ **Do:**
```python
# Environment variables
import os
client = UHAClient(token=os.getenv('UHA_API_TOKEN'))
```

### 2. Error Handling

```python
from uha_client import UHAClient, RateLimitError, AuthenticationError

client = UHAClient(token=os.getenv('UHA_API_TOKEN'))

try:
    result = client.encode(ra=180.0, dec=45.0, distance=100.0)
except RateLimitError as e:
    # Back off and retry
    time.sleep(e.retry_after)
except AuthenticationError:
    # Refresh token
    client.refresh_token()
except Exception as e:
    # Log and alert
    logger.error(f"UHA API error: {e}")
```

### 3. Rate Limit Management

```python
import time

def rate_limited_encode(coords_list):
    results = []
    for coords in coords_list:
        try:
            result = client.encode(**coords)
            results.append(result)
        except RateLimitError as e:
            time.sleep(e.retry_after)
            # Retry
            result = client.encode(**coords)
            results.append(result)

        # Respect 1 req/sec limit
        time.sleep(1.1)

    return results
```

### 4. Connection Pooling

```python
# Reuse client instance
class UHAService:
    def __init__(self):
        self.client = UHAClient(token=os.getenv('UHA_API_TOKEN'))

    def encode(self, **kwargs):
        return self.client.encode(**kwargs)

# Global instance
uha = UHAService()
```

### 5. Logging

```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('uha_client')

# Client logs all requests
client = UHAClient(
    token=os.getenv('UHA_API_TOKEN'),
    logger=logger
)
```

---

## Troubleshooting

### "Access denied: Source IP not in allowed VPC range"

Your IP needs to be whitelisted. Contact admin@got.gitgap.org with your IP address.

### "Rate limit exceeded"

You've hit the 1000 requests/day limit. Wait until midnight UTC or contact admin for quota increase.

### "Authentication credentials were not provided"

Missing or malformed `Authorization` header. Ensure format:
```
Authorization: Bearer uha.admin.YOUR_TOKEN_HERE
```

### Connection Timeout

- Check firewall allows HTTPS (port 443)
- Verify DNS resolves `got.gitgap.org`
- Increase timeout in client config

---

## Examples Repository

Complete examples: https://github.com/abba-01/uha-blackbox/tree/main/examples

- `/examples/python/` - Python scripts
- `/examples/php/` - PHP examples
- `/examples/joomla/` - Joomla component integration
- `/examples/javascript/` - Browser and Node.js
- `/examples/r/` - R scripts and notebooks

---

## Support

- **Documentation:** https://github.com/abba-01/uha-blackbox/docs
- **API Spec:** [API_SPECIFICATION.md](API_SPECIFICATION.md)
- **Issues:** https://github.com/abba-01/uha-blackbox/issues
- **Email:** admin@got.gitgap.org

---

**Version:** 1.0.0
**Last Updated:** 2025-11-01
