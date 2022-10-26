# NixOS System Configurations

Heavily inspired by [Mitchell Hashimoto's configuration](https://github.com/mitchellh/nixos-config).

## Setup

Build the ISO. This will use the [`nixos/nix` Docker image](https://hub.docker.com/r/nixos/nix) to create an `./iso` directory containing the `nixos.iso` file and an `./ssh` directory containing an RSA key.

```bash
$ make iso
```

Create a new virtual machine in VMware.

![Select Installation Method](images/01-select-installation-method.png?raw=true)

Drag the `./iso/nixos.iso` image onto the installer window.

![Create a New Virtual Machine](images/02-create-a-new-virtual-machine.png?raw=true)

Choose the **Linux > Other Linux 5.x kernel 64-bit ARM** option.

![Choose Operating System](images/03-choose-operating-system.png?raw=true)

Click **Customize Settings**.

![Finish](images/04-finish.png?raw=true)

Recommended Settings:

 * Camera
   * Remove Camera
 * Sound Card
 	* Remove Sound Card
 * Processors and Memory
   * Processors: 6 processor cores
   * Memory: 32768 MB
 * Network Adapter
   * Bridged Networking > Autodetect
 * Hard Disk
   * Disk size: 200 GB
 * Display
   * Use full resolution for Retina display

Start the virtual machine and let it complete the automatic installation process.

![Login Prompt](images/05-login-prompt.png?raw=true)

Login with username `developer` and password `developer` then type **`ifconfig`** to get the assigned IP address.

```bash
$ ifconfig
docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 172.17.255.255
        ether 02:42:91:de:0e:fd  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

ens160: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.1.99  netmask 255.255.255.0  broadcast 192.168.1.255
        inet6 fe80::20c:29ff:fe9a:f61c  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:9a:f6:1c  txqueuelen 1000  (Ethernet)
        RX packets 411  bytes 64479 (62.9 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 221  bytes 45702 (44.6 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
        device interrupt 49  memory 0x38500000-38520000

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 80  bytes 6400 (6.2 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 80  bytes 6400 (6.2 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

In your local terminal, export the `NIXADDR` environment variable to the IP address of the virtual machine (in the example above the IP is `192.168.1.99`) and start the bootstrap procedure.

The bootstrap procedure partitions the drive and installs NixOS using the settings in [`./configuration.nix`](configuration.nix).

```bash
$ export NIXADDR=192.168.1.99
$ make bootstrap
```

After restarting the installation is complete. Shut down the VM and disconnect the ISO image in VMware CD/DVD.

## Usage

### Updating

Update the [`./configuration.nix`](configuration.nix) file.

In your local terminal, export the `NIXADDR` environment variable to the IP address of the virtual machine then run `make update`.

```bash
$ export NIXADDR=192.168.1.99
$ make update
```

### SSH Access

The `make iso` command creates creates an `./ssh/id_rsa` file which can be used to access the VM.

```bash
$ ssh -i ./ssh/id_rsa developer@192.168.1.99
```

### Password

To update the default `developer` user password copy the output of a sha512 hash from `mkpasswd` into `users.users.developer.hashedPassword`.

```bash
$ docker run --rm -ti alpine:latest mkpasswd -m sha512 YOUR-NEW-PASSWORD
```
