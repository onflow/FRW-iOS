# FLOW Reference Wallet-iOS

## How to build

1. Checkout code.
   
2. ```git lfs fetch``` to fetch large frameworks file.

3. Install dependencies using ```Swift Package Manager```

4. Add a new file ```LocalEnv``` in ```/Lilico/App/Env/``` with these contents below
    ```
    {
        "WalletConnectProjectID": "",
        "BackupAESKey": "",
        "AESIV": "",
        "TranslizedProjectID": "",
        "TranslizedOTAToken": ""
    }
    ```

5. Add the necessary files in the following locations
   - For ```FRW``` target:
    ```
    /FRW/App/Env/Prod/GoogleOAuth2.plist
    /FRW/App/Env/Prod/GoogleService-Info.plist
    ```

   - For ```FRW-dev``` target: 
    ```
    /FRW/App/Env/Dev/GoogleOAuth2.plist
    /FRW/App/Env/Dev/GoogleService-Info.plist
    ```

6. Make iCloud and Widget work:
    - For ```FRW``` target: search and replace ```com.flowfoundation.wallet```
    - For ```FRW-dev``` target: search and replace ```com.flowfoundation.wallet```
