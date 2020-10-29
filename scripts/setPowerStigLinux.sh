# Register the Microsoft RedHat repository
curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo

# Install PowerShell
sudo yum install -y powershell

# Optional installation method
# sudo yum install https://github.com/PowerShell/PowerShell/releases/download/v7.0.3/powershell-lts-7.0.3-1.rhel.7.x86_64.rpm

# Install OMI
wget https://github.com/Microsoft/omi/releases/download/v1.1.0-0/omi-1.1.0.ssl_100.x64.rpm
wget https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1-294/dsc-1.1.1-294.ssl_100.x64.rpm

sudo rpm -Uvh omi-1.1.0.ssl_100.x64.rpm dsc-1.1.1-294.ssl_100.x64.rpm

# Start PowerShell
pwsh

install-module nx

