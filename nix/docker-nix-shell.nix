{
  pkgs ? import <nixpkgs> {},
  userName ? "$USER",
  homeDir ? "$HOME",
  extraPreamble ? "",
  extraDockerfile ? [],
  # default to work in the current working directory in the container
  docker-run-options ? ["-w" ''"$PWD"'' ''-v "$PWD:$PWD"''],
  docker-container-args ? ''"''${@}"'',
}: let
  inherit (pkgs) lib;

  dockerfile = pkgs.writeText "Dockerfile" ''
    FROM debian:bookworm-slim

    ARG USER_NAME
    ARG HOME

    RUN apt-get update \
      && apt-get install -y curl \
      && rm -rf /var/lib/apt/lists/* \
      && useradd -m -d $HOME $USER_NAME \
      && curl -sSfL https://artifacts.nixos.org/nix-installer \
            | sh -s -- install linux --init none --enable-flakes --no-confirm \
      && chown -R $USER_NAME:$USER_NAME /nix

    USER $USER_NAME
    ENV HOME=$HOME
    RUN mkdir /nix/_cache_nix && ln -s /nix/_cache_nix "$HOME/.cache"
    ENV PATH="''${HOME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:''${PATH}"

    ${lib.concatStringsSep "\n" extraDockerfile}
  '';
  docker-nix-shell = pkgs.writeShellApplication {
    name = "docker-nix-shell";
    extraShellCheckFlags = ["-e" "SC2145"];
    text = ''
      USER_NAME=${userName}
      HOME_DIR=${homeDir}
      VOL="docker-nix-store-$USER_NAME"

      IMAGE_NAME="docker-nix-$USER_NAME"
      TAG="${builtins.hashFile "md5" dockerfile}"
      IMAGE="$IMAGE_NAME:$TAG"

      function init() {
        if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
          docker build -t "$IMAGE_NAME:latest" -t "$IMAGE" \
            --build-arg "USER_NAME=$USER_NAME" \
            --build-arg "HOME=$HOME_DIR" \
            - < ${dockerfile}
          docker volume rm "$VOL" || true
        fi
        docker volume create "$VOL" > /dev/null
      }

      ${extraPreamble}

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
