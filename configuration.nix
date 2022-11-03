{ config, pkgs, ... }:
let

  moto-reset = pkgs.writeShellScriptBin "moto-reset" ''
    curl -XPOST http://127.0.0.1:5000/moto-api/reset -s | jq '.status' -r
  '';

in
{

  imports = [
    ./modules/vmware-guest.nix
  ];

  boot.initrd.availableKernelModules = [ "uhci_hcd" "ahci" "xhci_pci" "nvme" "usbhid" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  # Be careful updating this.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix = {
    # use unstable nix so we can access flakes
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      sandbox = false
    '';

    settings = {
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  # We expect to run the VM on hidpi machines.
  # hardware.video.hidpi.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # VMware, Parallels both only support this being 0 otherwise you see
  # "error switching console mode" on boot.
  boot.loader.systemd-boot.consoleMode = "0";

  # Define your hostname.
  networking.hostName = "nixos";

  # Set your time zone.
  time.timeZone = "America/New_York";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  # Virtualization settings
  virtualisation.docker.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";


  systemd.services = {
    mutagen = {
      description = "Mutagen Daemon";
      enable = true;
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "sshd.service" ];
      environment = {
        HOME = "/home/developer";
      };
      path = [
        pkgs.mutagen
      ];
      serviceConfig = {
        Type = "forking";
        User = config.users.users.developer.name;
        ExecStart = "${pkgs.mutagen}/bin/mutagen daemon start";
        ExecStop = "${pkgs.mutagen}/bin/mutagen daemon stop";
      };
    };
    moto = {
      description = "Moto Daemon";
      enable = true;
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ ];
      environment = {
        HOME = "/home/developer";
      };
      path = [
        pkgs.python3Packages.moto
      ];
      serviceConfig = {
        Type = "simple";
        User = config.users.users.developer.name;
        ExecStart = "${pkgs.python3Packages.moto}/bin/moto_server";
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cachix
    gnumake
    killall
    parted
    mutagen
    git
    terraform
    yarn
    nodejs
    jq
    python3Packages.moto
    awscli
    moto-reset
    vim
  ];

  programs.mtr.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  services.openssh.permitRootLogin = "no";

  # Disable the firewall since we're in a VM and we want to make it
  # easy to visit stuff in here. We only use NAT networking anyways.
  networking.firewall.enable = false;

  # Setup qemu so we can run x86_64 binaries
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  # Disable the default module and import our override. We have
  # customizations to make this work on aarch64.
  disabledModules = [ "virtualisation/vmware-guest.nix" ];

  # Interface is this on M1
  networking.interfaces.ens160.useDHCP = true;

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # This works through our custom module imported above
  virtualisation.vmware.guest.enable = true;

  fileSystems."/host" = {
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    device = ".host:/";
    options = [
      "umask=22"
      "uid=1000"
      "gid=1000"
      "allow_other"
      "auto_unmount"
      "defaults"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

  users.users.developer = {
    isNormalUser = true;
    home = "/home/developer";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.bashInteractive;
    hashedPassword = "$5$gKj78DetZb1oimOD$hGOEvmfZMPKTmmVXK7qN78uZ2Y2nwEFwYI2LDt0hXV6";
    openssh.authorizedKeys.keys = [ (builtins.readFile ./ssh/id_rsa.pub) ];
  };
}
