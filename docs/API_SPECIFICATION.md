# UHA API Specification v1.0

**Base URL:** `https://got.gitgap.org/v1/`

**Authentication:** Bearer token in Authorization header

**Last Updated:** 2025-11-01

---

## Authentication

All API requests (except `/health/`) require a Bearer token:

```http
Authorization: Bearer uha.admin.{random}.{observer}.{permissions}
```

**Token Format:**
- Legacy: `uha.admin.{random}.{observer}.{permissions}`
- UHA Address: `UHA1-xxxx-xxxx-xxxx`

**Example:**
```bash
curl -H "Authorization: Bearer uha.admin.k3IGwhX3SvGF4Iq7WAtFfA.joomla_allyourbaseline.read,write" \
     https://got.gitgap.org/v1/uha/anchor
```

---

## Rate Limits

- **Tier 1:** 1 request per second (burst protection)
- **Tier 2:** 1000 requests per day (daily quota)

**Headers:**
- `X-RateLimit-Limit`: Total quota
- `X-RateLimit-Remaining`: Requests remaining
- `X-RateLimit-Reset`: Unix timestamp when quota resets

**Rate Limit Exceeded (429):**
```json
{
  "error": "Rate limit exceeded",
  "retry_after": 3600
}
```

---

## Endpoints

### Health Check

**GET /health/**

Public endpoint (no authentication required)

**Response:**
```json
{
  "status": "ok",
  "service": "uha_service",
  "timestamp": "2025-11-01T05:00:00.000000+00:00"
}
```

---

### Get UHA Anchor

**GET /v1/uha/anchor**

Get the canonical UHA anchor tuple.

**Authentication:** Required

**Response:**
```json
{
  "version": "dynamic",
  "anchor_data": {
    "version": "1.0.0",
    "anchor": {
      "uha_root": "UHA1-ROOT-0000-0000-0000-0000",
      "timestamp": "2025-10-28T00:00:00Z",
      "algorithm": "UHA-SHA256-ED25519",
      "network": "testnet"
    },
    "status": "ok"
  },
  "source": "binary"
}
```

---

### Encode Coordinates to UHA

**POST /v1/uha/encode**

Encode astronomical coordinates to a UHA address.

**Authentication:** Required

**Request:**
```json
{
  "ra": 180.0,
  "dec": 45.0,
  "distance": 100.0,
  "resolution_bits": 16,
  "scale_factor": 1.0,
  "cosmo_params": {
    "h0": 67.4,
    "omega_m": 0.315,
    "omega_lambda": 0.685
  }
}
```

**Response:**
```json
{
  "uha_address": "UHA1-3F2A-8B9C-1D4E",
  "morton_code": 1045876,
  "resolution": 16,
  "cell_size_mpc": 15.26
}
```

---

### Decode UHA to Coordinates

**POST /v1/uha/decode**

Decode a UHA address back to coordinates.

**Authentication:** Required

**Request:**
```json
{
  "uha_address": "UHA1-3F2A-8B9C-1D4E"
}
```

**Response:**
```json
{
  "ra": 180.0,
  "dec": 45.0,
  "distance": 100.0,
  "resolution": 16,
  "morton_code": 1045876
}
```

---

### Multi-Resolution Tensor Calibration

**POST /v1/merge/multiresolution/**

Run multi-resolution systematic bias correction.

**Authentication:** Required

**Request:**
```json
{
  "dataset_id": "planck18/kids1000",
  "resolution_schedule": [8, 12, 16, 20, 24],
  "systematic_corrections": ["photo_z", "shear_cal", "baryonic"]
}
```

**Response:**
```json
{
  "status": "complete",
  "convergence_metric": 0.133,
  "converged": true,
  "corrections_applied": {
    "8_bit": 0.004,
    "12_bit": 0.006,
    "16_bit": 0.008,
    "20_bit": 0.004,
    "24_bit": 0.002
  }
}
```

---

### Request Token (Public)

**POST /api/request-token**

Public endpoint to request an API token.

**Authentication:** None

**Request:**
```json
{
  "observer": "my_application",
  "email": "user@example.com",
  "use_case": "Cosmology research"
}
```

**Response:**
```json
{
  "status": "pending",
  "message": "Token request received. Check email for approval."
}
```

---

## Admin Endpoints

Require admin-level authentication.

### List Tokens

**GET /v1/admin/token/list**

List all active tokens.

**Response:**
```json
{
  "tokens": [
    {
      "token": "uha.admin.k3IG...",
      "observer": "joomla_allyourbaseline",
      "permissions": "read,write",
      "created_at": "2025-11-01T00:00:00Z",
      "last_used": "2025-11-01T05:00:00Z"
    }
  ]
}
```

---

### Create Token

**POST /v1/admin/token/create**

Create a new API token.

**Request:**
```json
{
  "observer": "new_observer",
  "permissions": "read,write"
}
```

**Response:**
```json
{
  "token": "uha.admin.xyz123...",
  "observer": "new_observer",
  "permissions": "read,write",
  "created_at": "2025-11-01T05:00:00Z"
}
```

---

### Revoke Token

**POST /v1/admin/token/revoke**

Revoke (tombstone) an API token.

**Request:**
```json
{
  "token": "uha.admin.xyz123...",
  "reason": "Security rotation"
}
```

**Response:**
```json
{
  "status": "tombstoned",
  "token": "uha.admin.xyz123...",
  "tombstoned_at": "2025-11-01T05:00:00Z"
}
```

---

### Get Usage Stats

**GET /v1/admin/usage/{observer}**

Get usage statistics for an observer.

**Response:**
```json
{
  "observer": "joomla_allyourbaseline",
  "daily_limit": 1000,
  "current_count": 42,
  "reset_date": "2025-11-02",
  "total_requests": 15234
}
```

---

### System Metrics

**GET /v1/metrics/**

Get system-wide metrics.

**Response:**
```json
{
  "total_requests_today": 5432,
  "active_observers": 12,
  "cache_hit_rate": 0.73,
  "avg_response_time_ms": 145
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "error": "Error message",
  "error_code": "specific_error_code",
  "status_code": 400
}
```

### Common Error Codes

| Code | Status | Description |
|------|--------|-------------|
| `not_authenticated` | 401 | Missing or invalid token |
| `permission_denied` | 403 | Insufficient permissions |
| `not_found` | 404 | Resource not found |
| `rate_limit_exceeded` | 429 | Too many requests |
| `invalid_request` | 400 | Malformed request |
| `server_error` | 500 | Internal server error |

---

## IP Whitelisting

API access is restricted to whitelisted IPs:

- VPC Range: `10.124.0.0/20`
- Allowed IPs: Contact admin to whitelist

**Access Denied (403):**
```json
{
  "error": "Access denied: Source IP not in allowed VPC range",
  "ip": "1.2.3.4"
}
```

---

## Pagination

Endpoints that return lists support pagination:

**Query Parameters:**
- `page`: Page number (default: 1)
- `page_size`: Results per page (default: 50, max: 1000)

**Response:**
```json
{
  "count": 250,
  "next": "https://got.gitgap.org/v1/endpoint?page=2",
  "previous": null,
  "results": [...]
}
```

---

## Versioning

Current version: **v1**

The API version is included in the URL path. Future versions will be at `/v2/`, `/v3/`, etc.

**Deprecation Policy:**
- Each version supported for 12 months after next version release
- Breaking changes require new version
- 6-month advance notice for deprecation

---

## SDKs

Official client libraries:

- **Python:** `pip install uha-client`
- **JavaScript:** `npm install uha-client-js`
- **PHP:** `composer require uha/client`
- **R:** `install.packages("uha")`

---

## Support

- **Documentation:** https://github.com/abba-01/uha-blackbox
- **Issues:** https://github.com/abba-01/uha-blackbox/issues
- **Email:** admin@got.gitgap.org

---

**Version:** 1.0.0
**Last Updated:** 2025-11-01
**License:** See LICENSE file in repository
