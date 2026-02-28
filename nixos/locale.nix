{ config, pkgs, vars, ... }:

{
  time.timeZone = vars.timezone;

  i18n = {
    defaultLocale = vars.locale;
    extraLocaleSettings = {
      LC_ADDRESS = vars.locale;
      LC_IDENTIFICATION = vars.locale;
      LC_MEASUREMENT = "pl_PL.UTF-8";
      LC_MONETARY = "pl_PL.UTF-8";
      LC_NAME = vars.locale;
      LC_NUMERIC = vars.locale;
      LC_PAPER = "pl_PL.UTF-8";
      LC_TELEPHONE = "pl_PL.UTF-8";
      LC_TIME = "pl_PL.UTF-8";
    };
  };

  # Console keymap
  console.keyMap = "pl";
}
