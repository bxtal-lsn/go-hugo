# Golang

Go (or Golang) is a statically-typed, compiled programming language created at Google by Robert Griesemer, Rob Pike, and Ken Thompson.  
It features garbage collection, memory safety, structural typing, and CSP-style concurrency with goroutines and channels.  
Go emphasizes simplicity with a minimal syntax that reduces language complexity and speeds compilation.  
Its standard library provides robust networking, HTTP, and file system support without external dependencies.  
Go's build system produces single statically-linked binaries for easy deployment across platforms.  
The language targets systems programming, microservices, and distributed applications where performance matters.  
Go combines the efficiency of compiled languages with the development speed of interpreted languages through features like gofmt for standardized formatting, built-in testing, and a race detector.  
Notable for its fast compilation and execution, Go has become popular for cloud infrastructure, DevOps tools, and backend services.

## Installation

Remove any previous Go installation by deleting the /usr/local/go folder (if it exists), then extract the archive you just downloaded into /usr/local, creating a fresh Go tree in /usr/local/go:
```bash
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.3.linux-amd64.tar.gz
```
(You may need to run the command as root or through `sudo`).
 **Do not** untar the archive into an existing /usr/local/go tree. This is known to produce broken Go installations.

download the appropriate version of GO, for example
```bash
sudo wget /usr/local https://go.dev/dl/go1.23.3.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.3.linux-amd64.tar.gz
```
    
Add /usr/local/go/bin to the `PATH` environment variable.
You can do this by adding the following line to your $HOME/.profile or /etc/profile (for a system-wide installation):
```bash
vim $HOME/.profile
```
insert following into the opened file
```bash
export PATH=$PATH:/usr/local/go/bin
```
then run source to apply the changes in system
```bash
source $HOME/.profile
```
    
**Note:** Changes made to a profile file may not apply until the next time you log into your computer. To apply the changes immediately, just run the shell commands directly or execute them from the profile using a command such as `source $HOME/.profile`.`  
    
Verify that you've installed Go by opening a command prompt and typing the following command:
```bash
go version
```    
Confirm that the command prints the installed version of Go.
