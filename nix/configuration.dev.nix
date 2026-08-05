# Copyright (C) 2025 Ergon Informatik AG
# SPDX-FileCopyrightText: 2026 Alain Lehmann
#
# SPDX-License-Identifier: MIT
{
  pkgs,
  config,
  lib,
  ...
}: let
  gitRoot = config.git.root.shellVariable;
in {
  # NOTE: configuration.dev.nix is for local developer environment
  # this (typically) extends configuration.ci.nix with dev-only dependencies
  imports = [./configuration.ci.nix ./docker-nix-shell.module.nix];

  git.root.enable = true;
  docker-sandbox.enable = true;
  docker-sandbox.direnv.enable = true;
  docker-sandbox.mounts.readWrite = [gitRoot];
  docker-sandbox.mounts.readOnly = ["${gitRoot}/nix"];

  # enable treefmt for formatting with multiple formatters
  # https://github.com/numtide/treefmt-nix?tab=readme-ov-file#supported-programs
  ##  treefmt.enable = true;
  #  treefmt.programs.alejandra.enable = true;
  #  treefmt.programs.ktlint.enable = true;

  #additional packages: search.nixos.org
  packages = [
    #pkgs.k9s
    #pkgs.google-cloud-sdk
    #pkgs.awscli2
    #pkgs.terraform
    #pkgs.kubectl
    #pkgs.kubernetes-helm
    #pkgs.k9s
  ];
}
