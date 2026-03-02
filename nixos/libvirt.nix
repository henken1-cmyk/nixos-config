{ config, pkgs, vars, ... }:

{
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
