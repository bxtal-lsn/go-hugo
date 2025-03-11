# Add Certficate to WSL Instance

WSL does not have access to external resources if it does not have a valid certificate.

## Oracle Linux
```shell
# this should NOT work the first time you log into oracle linux
sudo yum update -y

# cd to the certifacte store
cd /etc/pki/ca-trust/source/anchors/

# use vim and paste the certificate into this file and save
sudo vim my-cert.crt

# activate the certificate
sudo update-ca-trust

# verify that the certificate is installed
sudo openssl verify /etc/pki/ca-trust/source/anchors/my-cert.crt

# Now it should work
sudo yum update -y

```

## Ubuntu
```shell
# This should NOT work the first time if there is no valid certificate
sudo apt update -y

# Change to the certificate store directory
cd /usr/local/share/ca-certificates/

# Use vim to create and edit the certificate file
sudo vim my-cert.crt

# Update the certificate store
sudo update-ca-certificates

# Verify that the certificate is installed
sudo openssl verify /usr/local/share/ca-certificates/my-cert.crt

# Now it should work
sudo apt update -y
```
