# SPDX-FileCopyrightText: 2026 Alain Lehmann
#
# SPDX-License-Identifier: MIT
{
  pkgs,
  lib,
  ...
}: let
  reuse = {options ? [], ...} @ args:
    args
    // {
      command = lib.getExe pkgs.reuse;
      options = ["annotate" "--license" "MIT" "--copyright" "Alain Lehmann"] ++ options;
    };
in {
  treefmt.enable = true; # enable treefmt for formatting with multiple formatters
  treefmt.pre-commit-hook = true;
  treefmt.programs.alejandra.enable = true;
  treefmt.settings.formatter = {
    reuse = reuse {
      options = ["--skip-unrecognised"];
      includes = ["*"];
      excludes = [".envrc" "README.md"];
    };
    reuse-dockerfiles = reuse {
      options = ["--style=python"];
      includes = ["**/Dockerfile*"];
    };
  };

  #  # https://github.com/numtide/treefmt-nix?tab=readme-ov-file#supported-programs
  #  treefmt.programs.alejandra.enable = true; #nix linter
  #  treefmt.programs.ktlint.enable = true;
  #  # installing pre-commit hook is optional
  #  treefmt.pre-commit-hook = true;
  #
  # other packages (see search.nixos.org)
  packages = [
    pkgs.curl
    pkgs.git # workaround in nix-shell-parts that implicitly depends on git
  ];
}
