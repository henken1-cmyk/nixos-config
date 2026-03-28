{ config, pkgs, vars, ... }:

{
  programs.git = {
    enable = true;
    signing.format = null;

    settings = {
      user.name = vars.gitUsername;
      user.email = vars.email;
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
      diff.algorithm = "histogram";
      merge.conflictstyle = "zdiff3";
      rerere.enabled = true;
      credential."https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      syntax-theme = "base16";
    };
  };
}
