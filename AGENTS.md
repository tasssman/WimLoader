# Repository instructions

- Before editing files, tell the user which files you plan to change and summarize the intended changes. Wait for the user's explicit confirmation before making any edits.
- Do not modify `createWinPEFromScratch.bat` unless the user explicitly asks for a change to that file.

# Mantis integration

- The Mantis instance is `https://bug.miasik.com/` and the Wim Loader project ID is `5`. Write issues in English.
- For Mantis API requests, retrieve the token from Windows Credential Locker using `Windows.Security.Credentials.PasswordVault`, resource `Copilot-WimLoader-Mantis` and username `mantis-api`. The credential is available only in the Windows account where it was stored.
- Send the token as the raw `Authorization` header value, without a `Bearer` prefix. Never print the token or include it in commands, repository files, or chat messages.
- If the credential is unavailable, ask the user to configure access; do not assume anonymous requests are authenticated.
