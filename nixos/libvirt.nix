{ config, pkgs, vars, ... }:

{
  # Fix: upstream service hardcodes /usr/bin/sh which doesn't exist on NixOS.
  # Use overrideStrategy to emit an empty ExecStart= line before the replacement.
  systemd.services.virt-secret-init-encryption = {
    overrideStrategy = "asDropin";
    serviceConfig.ExecStart = let
      sh = "${pkgs.bash}/bin/sh";
      systemd-creds = "${config.systemd.package}/bin/systemd-creds";
      dd = "${pkgs.coreutils}/bin/dd";
    in pkgs.lib.mkForce [
      ""
      "${sh} -c 'umask 0077 && (${dd} if=/dev/random status=none bs=32 count=1 | ${systemd-creds} encrypt --name=secrets-encryption-key - /var/lib/libvirt/secrets/secrets-encryption-key)'"
    ];
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true; # TPM 2.0 emulation (Win11 requirement)
    };
  };

  programs.virt-manager.enable = true;

  # SPICE USB redirection (passthrough USB devices to VM)
  virtualisation.spiceUSBRedirection.enable = true;

  # OVMF UEFI firmware with Secure Boot (stable paths for scripts)
  environment.etc."ovmf/OVMF_CODE.ms.fd".source = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
  environment.etc."ovmf/OVMF_VARS.ms.fd".source = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";

  # SPICE viewer + swtpm (needed standalone for windows-vm.sh script)
  environment.systemPackages = [ pkgs.virt-viewer pkgs.swtpm ];
}
