{
  pkgs ? import <nixpkgs> {},
  #user ? ''"$USER"'',
  user ? "claude",
  projectDir ? "/project",
  gitRoot,
  docker-run-options ? [''-v "${gitRoot}:${projectDir}" -w ${projectDir}''],
  docker-container-args ? ''"''${@}"'',
  enableDirenv ? false,
}: let
  inherit (pkgs) lib;

  dockerfile = pkgs.writeText "Dockerfile" ''
    FROM debian:bookworm-slim

    ARG USER_NAME=claude

    RUN apt-get update \
      && apt-get install -y curl \
      && rm -rf /var/lib/apt/lists/* \
      && useradd -m $USER_NAME \
      && curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install linux --init none --enable-flakes --no-confirm \
      && chown -R $USER_NAME:$USER_NAME /nix

    USER $USER_NAME
    RUN mkdir /nix/_cache_nix && ln -s /nix/_cache_nix ~/.cache
    ENV PATH="/home/''${USER_NAME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:''${PATH}"

    ${
      if enableDirenv
      then "RUN nix profile install nixpkgs#direnv nixpkgs#nix-direnv"
      else ""
    }

    # workaround for /project being root owned when `docker run ... command`
    RUN cat > ~/.gitconfig <<EOF
    [safe]
      directory = ${projectDir}
    EOF
  '';
  docker-nix-shell = pkgs.writeShellApplication {
    name = "docker-nix-shell";
    text = ''
      USER_NAME=${user}
      VOL="docker-nix-store-$USER_NAME"

      IMAGE_NAME="docker-nix-$USER_NAME"
      TAG="${builtins.hashFile "md5" dockerfile}"
      IMAGE="$IMAGE_NAME:$TAG"

      function init() {
        if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
          docker build -t "$IMAGE_NAME:latest" -t "$IMAGE" --build-arg "USER_NAME=$USER_NAME" - < ${dockerfile}
          docker volume rm "$VOL" || true
        fi
        docker volume create "$VOL" > /dev/null
      }

      function stripProject() {
        echo "''${1/#${gitRoot}/${projectDir}}"
      }

      function run() {
        docker run --rm -ti -v "$VOL:/nix" ${lib.concatStringsSep " " docker-run-options} "$IMAGE" ${docker-container-args}
      }

      function testrun() {
        run nix run 'nixpkgs#hello'
      }

      init && run "$@"
    '';
  };
in
  docker-nix-shell
