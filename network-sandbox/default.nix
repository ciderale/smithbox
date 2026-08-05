# SPDX-FileCopyrightText: 2026 Alain Lehmann
#
# SPDX-License-Identifier: MIT

{pkgs, ...}: {
  packages.smithbox = pkgs.writeShellApplication {
    name = "smithbox";
    runtimeEnv.DOCKER_BUILD_CONTEXT = ./.;
    text = builtins.readFile ./smithbox.sh;
  };
}
