# SSH Setup Instructions

## Quick Setup (Manual Steps)

### Step 1: Copy your SSH public key

Open PowerShell and run:

```powershell
cd D:\Dropbox\projects\midi_cs\controller_v2\package\scripts\deploy
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
```

Copy the output (it starts with `ssh-ed25519`).

### Step 2: SSH to your Pi

```powershell
ssh mastrctrl@192.168.1.195
```

When prompted, enter password: `mastri`

### Step 3: On the Pi, set up SSH key authentication

Once connected to the Pi, run these commands:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
```

In nano, paste your public key (from Step 1), then:
- Press `Ctrl+X` to exit
- Press `Y` to save
- Press `Enter` to confirm

Then set permissions:

```bash
chmod 600 ~/.ssh/authorized_keys
exit
```

### Step 4: Test passwordless SSH

Back on Windows, test:

```powershell
ssh mastrctrl@192.168.1.195 "echo 'SSH key auth works!'"
```

If it works without asking for a password, you're done!

### Step 5: Test deploy script

```powershell
cd D:\Dropbox\projects\midi_cs\controller_v2\package\scripts\deploy
bash deploy.sh --verify 192.168.1.195 mastrctrl
```

## Alternative: Use ssh-copy-id (if available)

If you have Git Bash or WSL, you can use:

```bash
ssh-copy-id mastrctrl@192.168.1.195
```

Enter password `mastri` when prompted.

