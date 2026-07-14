# 🔒 Security

## API Keys & Secrets

Firebase API keys are stored in environment variables, **not** in source code.

### Setup

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Get your Firebase API keys from: https://console.firebase.google.com/project/diuevents-3ecd4/settings/general

3. Fill in the `.env` file with your actual keys.

4. **Never commit `.env` to version control.** It is already in `.gitignore`.

**Steps to revoke:**
1. Go to [Firebase Console](https://console.firebase.google.com/project/diuevents-3ecd4/settings/serviceaccounts/adminsdk)
2. Navigate to **Project Settings > Security > API Keys**
3. Delete or rotate the leaked keys
4. Update your `.env` file with new keys
5. Run `flutter clean` and rebuild

### Best Practices

- Always use `.env` files for secrets
- Rotate keys regularly
- Never share API keys in public repositories
- Use Firebase App Check for additional protection
