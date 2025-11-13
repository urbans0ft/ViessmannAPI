# ViessmannAPI

Access the Viessmann Web API (aka ViCare)

The project is split up in a [Bash](/Bash/) and a [Powershell](/ViessmannPs/) part. The _Bash_
scripts are currently abandoned (feel free to contribute).

## Powershell Module

Import module and authorize at viessmann:

```powershell
Import-Module ViessmannPs
Connect-Viessmann -Credential (Get-Credential) -ClientId '<client-id>' -RedirectUri 'http://localhost:4200/' -Persist
```

Fill in credential information:

```
PowerShell credential request
Enter your credentials.
User: my@mail.com
Password for user my@mail.com: ******

Configuration persisted to: C:\Users\<user>\.ViessmanPs\config.json
OAuth information persisted to: C:\Users\<user>\.ViessmanPs\oauth.json
```

Since the first connect was made with parameter `-Persist` subsequent calls won't need parameters:

```powershell
Connect-Viessmann
```

```
OAuth information persisted to: C:\Users\nico\.ViessmanPs\oauth.json
```

## References

- [Viessmann API Documentation](https://api.viessmann-climatesolutions.com/documentation)
- [Viessmann Developer Portal](https://developer.viessmann-climatesolutions.com)
