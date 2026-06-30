#!/usr/bin/env sh

HOME=${HOME:-/home/me}
UID=${UID:-1000}
GID=${GID:-1000}
MODE=${MODE:-direnv}

case $MODE in
	direnv)
		EXECUTOR='direnv allow && exec direnv exec . "${@}"'
		;;
	nix-develop)
		EXECUTOR='exec nix develop --no-warn-dirty . --command "${@}"'
		;;
	plain)
		EXECUTOR='exec "${@}"'
		;;
	*)
		echo "Unknown mode $MODE"
		exit 1
		;;
esac

workaround_macos_volume_mount_permission() {
	sleep 1
}

ensure_store_permission() {
	owner=$(stat -c '%u:%g' /nix)
	if [ "$owner" != "$UID:$GID" ]; then
		echo "Fixing /nix ownership..."
		chown -R "$UID:$GID" /nix
	fi
}

ensure_home() {
	mkdir -p $HOME
	mkdir -p $HOME/.local/state/nix/profiles
	chown -R $UID:$GID $HOME
}

as_user() {
	exec gosu $UID:$GID sh -c "
		export HOME=$HOME
		. /etc/profile.d/nix.sh;
		$EXECUTOR
	" sh "$@"
}

update-ca-certificates
workaround_macos_volume_mount_permission
ensure_home
ensure_store_permission
as_user "${@}"
