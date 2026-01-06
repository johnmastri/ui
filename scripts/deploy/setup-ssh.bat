@echo off
echo Setting up SSH key authentication...
echo.
echo This will prompt you for the password: mastri
echo.
ssh mastrctrl@192.168.1.195 "mkdir -p ~/.ssh ^&^& chmod 700 ~/.ssh ^&^& echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICy47fbbb0IzTNB3bhZCXn6fgLWQetU1vSyEUEPqfT4h mastrctrl-deploy ^> ~/.ssh/authorized_keys ^&^& chmod 600 ~/.ssh/authorized_keys ^&^& echo Done!"
echo.
echo Testing passwordless SSH...
ssh mastrctrl@192.168.1.195 "echo SSH key authentication works!"
echo.
echo If you see the message above without entering a password, setup is complete!
pause

