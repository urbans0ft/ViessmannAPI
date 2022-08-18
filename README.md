# ViessmannAPI
Access the Viessmann Web API (aka ViCare)

## Usage

1. Copy `account.json` to `.account.json` and change the content as advised by the comment.
2. Execute `./login.sh` to obtain the authorization token.
3. The token is stored within .token.json

    ```
    {
      "access_token": "eyJlbmMi...VP8g",
      "refresh_token": "4f2...f28",
      "token_type": "Bearer",
      "expires_in": 3600
    }
    ```
