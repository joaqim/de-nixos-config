# Options specific to this particular host machine.

{ config, pkgs, lib, is, ... }:

let
  inherit (builtins) elem pathExists;
  inherit (lib) mkIf;
  inherit (lib.lists) optional;
  inherit (lib.strings) optionalString;
in

{
  imports = [
    ./hardware-configuration.nix
  ]
  ++ (optional (pathExists ./private.nix) ./private.nix);

  # TODO?: Maybe some options.my.xserver that fit my laptop's different GPUs and
  # display outputs and my monitor, which formalize how I want each combination
  # and which make it easy to switch, and which serve as a record of what I
  # figure out for them, and which control how the xserver config below is
  # constructed.

  # Define this again here to ensure it is checked that this is the same as what
  # /etc/nixos/configuration.nix also defined for the same option.
  my.hostName = "uni";

  my.zfs = {
    mirrorDrives = [  # Names under /dev/disk/by-id/
      "nvme-E2M2_64GB_MJU412D001CC9"
    ];
    partitions = {
      legacyBIOS = 1;
      EFI        = 2;
      boot       = 3;
      main       = 4;
      swap       = 5;
    };
    pools = let id = "k3gvze"; in {
      boot.name = "boot-${id}";
      main.name = "main-${id}";
    };
    usersZvolsForVMs = [
      { id = "1"; owner = "boss"; }
      { id = "2"; owner = "boss"; }
      { id = "3"; owner = "work"; }
      { id = "4"; owner = "work"; }
      # { id = "5"; owner = ; }
      # { id = "6"; owner = ; }
      # { id = "7"; owner = ; }
      # { id = "8"; owner = ; }
    ];
  };

  boot = {
    loader = {
      # If UEFI firmware can detect entries
      efi.canTouchEfiVariables = true;

      # # For problematic UEFI firmware
      # grub.efiInstallAsRemovable = true;
      # efi.canTouchEfiVariables = false;
    };

    # Not doing this anymore, because the latest kernel versions can cause problems due to being
    # newer than what the other packages in the stable NixOS channel expect.  E.g. it caused trying
    # to use a version of the VirtualBox extensions modules (or something) for the newer kernel but
    # this was marked broken which prevented building the NixOS system.
    #
    # # Use the latest kernel version that is compatible with the used ZFS
    # # version, instead of the default LTS one.
    # kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    # # Following https://nixos.wiki/wiki/Linux_kernel --
    # # Note that if you deviate from the default kernel version, you should also
    # # take extra care that extra kernel modules must match the same version. The
    # # safest way to do this is to use config.boot.kernelPackages to select the
    # # correct module set:
    # extraModulePackages = with config.boot.kernelPackages; [ ];

    kernelParams = [
      #"video=DP-3:3440x1440@100"  # Use 100 Hz, like xserver.
    ];

    zfs.requestEncryptionCredentials = false;  # Or could be a list of selected datasets.
  };

  users.users = let
    common = config.my.users.commonAttrs;
  in {
    # v = common // {  # No longer using. It's all backed-up.
    #   extraGroups = [ "audio" ];
    # };
  };

  my.zfs.encryptedHomes = {
    noAuto = [
    ];
  };

  # When booting into emergency or rescue targets, do not require the password
  # of the root user to start a root shell.  I am ok with the security
  # consequences, for this host.  Do not blindly copy this without
  # understanding.  Note that SYSTEMD_SULOGIN_FORCE is considered semi-unstable
  # as described in the file systemd-$VERSION/share/doc/systemd/ENVIRONMENT.md.
  systemd.services = {
    emergency.environment = {
      SYSTEMD_SULOGIN_FORCE = "1";
    };
    rescue.environment = {
      SYSTEMD_SULOGIN_FORCE = "1";
    };
  };

  networking = {
    # # TODO: Might be needed to work with my router's MAC filter.  Though, the
    # # default of macAddress="preserve" might work once it has connected once
    # # (with the MAC filter disabled temporarily), and the default
    # # scanRandMacAddress=true might be ok since it sounds like it only affects
    # # scanning but not "preserve"d MAC address of previously-connected
    # # connections.
    # networkmanager = {
    #   wifi = {
    #     scanRandMacAddress = false;
    #     macAddress = "permanent";
    #   };
    # };

    firewall = {
      logRefusedConnections = true;
      logRefusedPackets = true;
    };
  };

  # This only reflects the DNS servers that are configured elsewhere (e.g. by DHCP).
  # This does not define the DNS servers.
  # Try to avoid using this, because it hard-codes assumption about where I'm at.
  # If it must be used occasionally, remember you can `nixos-rebuild test` for ephemeral changes.
  my.DNSservers = let
    home-router = "192.168.11.1";
  in
    mkIf false
      [ home-router ];

  # If in a situation where an upstream DNS server does not support DNSSEC
  # (i.e. cannot even proxy DNSSEC-format datagrams), this could be defined so
  # that DNS should still work.
  # services.resolved.dnssec = "allow-downgrade";  # Or "false".

  # services.openssh.enable = true;
  # my.intended.netPorts.TCP = [22];

  time.timeZone = "Europe/Stockholm";

  console.font = "ter-v24n";

  hardware.cpu.amd.updateMicrocode = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Have dynamic CPU-frequency reduction based on load, to keep temperature and fan noise down
  # when there's light load, but still allow high frequencies (limited by the separate choice of
  # fan-speed-management-profile's curve's efficacy at removing heat) when there's heavy load.
  # Other choices for this are: "schedutil" or "ondemand".  I choose "conservative" because it
  # seems to not heat-up my CPUs as easily, e.g. when watching a video, which avoids turning-on
  # the noisy fans, but it still allows the highest frequency when under sustained heavy load
  # which is what I care about (i.e. I don't really care about the faster latency of "ondemand"
  # nor the somewhat-faster latency of "schedutil").  Note: maximum performance is attained with
  # the fans' speeds at the highest, which I have a different profile for in Tuxedo-rs's Tailor
  # that I switch between as desired.
  powerManagement.cpuFreqGovernor = "ondemand"; # TODO(jq): Test which profile I would prefer 

  services.xserver = {
    exportConfiguration = true;
  };

  #services.printing.drivers = [ pkgs.hplip ];

  hardware.sane = {
    enable = true;
    #extraBackends = [ pkgs.hplipWithPlugin ];
  };


  #my.allowedUnfree = [ "hplip" ];

  # Have debug-info and source-code for packages where this is applied.  This is for packages that
  # normally don't provide these, and this uses my custom approach that overrides and overlays
  # packages to achieve having these.
  my.debugging.support = {
    all.enable = false;
    sourceCode.of.prebuilt.packages = with pkgs; [
      # TODO: Unsure if this is the proper way to achieve this for having the Rust library source
      # that corresponds to binaries built by Nixpkgs' `rustc`.
      # Have the Rust standard library source.  Get it from this `rustc` package, because it
      # locates it at the same `/build/rustc-$VER-src/` path where its debug-info has it recorded
      # for binaries it builds, and because this seems to be the properly corresponding source.
      # TODO: is this true, or else where is its sysroot or whatever?
      (rustc.overrideAttrs (origAttrs: {
        # Only keep the `library` source directory, not the giant `src` (etc.) ones.  This greatly
        # reduces the size that is output to the `/nix/store`.  The `myDebugSupport_saveSrcPhase`
        # of `myLib.pkgWithDebuggingSupport` will run after ours and will only copy the
        # `$sourceRoot` as it'll see it as changed by us here.  If debugging of `rustc` itself is
        # ever desired, this could be removed so that its sources are also included (I think).
        preBuildPhases = ["myDebugSupport_rust_onlyLibraryDir"];
        myDebugSupport_rust_onlyLibraryDir = ''
          export sourceRoot+=/library
          pushd "$NIX_BUILD_TOP/$sourceRoot"
        '';
      }))
    ];
  };

  nix = {
    daemonCPUSchedPolicy = "idle"; daemonIOSchedClass = "idle";  # So builds defer to my tasks.
    settings = {
      extra-experimental-features = "nix-command flakes";
    };
  };

  # Enable Docker, run by non-root users.
  virtualisation.docker.rootless = {
    enable = true;
  };

  my.resolvedExtraListener =
    mkIf config.virtualisation.docker.rootless.enable
      # Choose an address that should be very unlikely to conflict with what
      # anything else needs to use.
      "192.168.255.54";
}