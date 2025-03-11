# Oracle Linux Automatic Updates

Refer to this page for automatic updates [Oracle Linux Automatic Updates](https://docs.oracle.com/en/operating-systems/oracle-linux/software-management/sfw-mgmt-UpdateSoftwareAutomatically.html)  

The DNF Automatic tool is provided as an extra package that you can use to keep the system automatically updated with the latest security patches and bug fixes. The tool can provide notifications of updates, download updates, and then install them automatically by using systemd timers.
You can install the `dnf-automatic` package and enable the systemd `dnf-automatic.timer` timer unit to start using this service:

```shell
sudo dnf install -y dnf-automatic
```

```shell
sudo systemctl enable --now dnf-automatic.timer
```


