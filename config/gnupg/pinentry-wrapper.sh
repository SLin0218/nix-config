#!/bin/bash
# If we are running inside agy (which runs on the GPG_TTY), bypass curses and use pinentry-mac
if [ "$PINENTRY_USER_DATA" = "USE_CURSES=1" ] && ! ([ -n "$GPG_TTY" ] && ps -t "${GPG_TTY#/dev/}" -o comm= 2>/dev/null | grep -qE "antigravity|agy"); then
	if command -v pinentry-curses >/dev/null 2>&1; then
		exec pinentry-curses "$@"
	elif [ -x "$HOME/.nix-profile/bin/pinentry-curses" ]; then
		exec "$HOME/.nix-profile/bin/pinentry-curses" "$@"
	elif [ -x "/run/current-system/sw/bin/pinentry-curses" ]; then
		exec "/run/current-system/sw/bin/pinentry-curses" "$@"
	else
		exec $HOMEBREW_PREFIX/bin/pinentry-mac "$@"
	fi
else
	exec $HOMEBREW_PREFIX/bin/pinentry-mac "$@"
fi
