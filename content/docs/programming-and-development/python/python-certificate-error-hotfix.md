# A hacky fix when pip and other python packages are not able to download through HTTPS.

Requests through HTTPS can be blocked when applications do the requests.

Requests are blocked because the self-signed certificate by *Sev* is not used. That certificate is called `ssev01` and can be found in `certmgr` on windows machines on the Sev IT environment.

## Solution:

`pip` and other python packages use the `certifi` library to manage certificates. The solution is to force `certifi` to recognize the `ssev01` certificate as a valid certificate.

The `certifi` library has a `cacert.pem` chained certificate file that contains all valid certificate keys. If the certificate key within `ssev01.cer` file is appended to the `cacert.pem` file, the `certifi` package will include this key as an accepted certificate.

## Step by step

1. Export the `ssev01` certificate to a `.cer` file, using the Windows Certificate Manager.
2. Make a backup of the `cacert.pem` file used by `certifi`.
    - This file can be located with the command `py -3.12 -m certifi` (Or some other python version)
3. Append the contents of Sev's certificate to the `cacert.pem` file. 
    - There are tools for appending a certificate to a Certificate chain file, but it is also possible to use copy-paste in a text editor
4. Save the file and try again.
