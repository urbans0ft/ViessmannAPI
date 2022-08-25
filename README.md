# ViessmannAPI

Access the Viessmann Web API (aka ViCare)

## Prerequisites

The following commands must be available:

- [`jq`](https://stedolan.github.io/jq/)
- [`curl`](https://curl.se/)

## Configuration

Copy `account.json` to `.account.json` and change the the values of "_account_" and "_client_" according to your settings (https://app.developer.viessmann.com/).

## Usage

### Login

```
$ ./api.sh --login
$ ./api.sh --discover
```

The token is stored within `.token.json` and used for subsequent api calls.

```
{
  "access_token": "eyJlbmMi...VP8g",
  "refresh_token": "4f2...f28",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

The discoverd setting is stored within `.setting.json`.

```
{
  "installationId": "123456",
  "gatewaySerial": "0123456789101112",
  "deviceId": "0"
}
```

## References

-  [Viessmann API Documentation](https://documentation.viessmann.com/static/getting-started)
