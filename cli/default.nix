{
  lib,
  writeShellApplication,
  coreutils,
  mango,
  quickshell,
  systemd,
  version ? "0.1.1",
}:

writeShellApplication {
  name = "omde";
  runtimeInputs = [
    coreutils
    mango
    quickshell
    systemd
  ];

  text = ''
    usage() {
      cat <<'USAGE'
    Usage: omde [COMMAND]

    Start OMDE. Inside a Mango session, start the shell through systemd or
    in the foreground. Outside one, start Mango.

    Commands:
      shell [--daemon]  Start the shell; --daemon detaches for compositor autostart.
      session           Start Mango.
      run               Run Quickshell in the foreground; used by omde.service.
      stop              Stop omde.service, or the running shell.
      restart           Restart omde.service.
      status            Show omde.service status.
      logs              Follow omde.service logs.
      help              Show this help.
    USAGE
    }

    unit_exists() {
      [ "$(systemctl --user show -p LoadState --value omde.service 2>/dev/null)" = "loaded" ]
    }

    in_mango() {
      [ -n "''${MANGO_INSTANCE_SIGNATURE:-}" ]
    }

    shell_running() {
      case "$(quickshell -c omde list -j 2>/dev/null)" in
        \[*) return 0 ;;
        *) return 1 ;;
      esac
    }

    start_shell() {
      if unit_exists; then
        exec systemctl --user start omde.service
      fi

      if shell_running; then
        return
      fi

      exec quickshell -c omde --no-duplicate
    }

    start() {
      if in_mango; then
        start_shell
      else
        exec mango
      fi
    }

    stop_shell() {
      if unit_exists; then
        systemctl --user stop omde.service
        return
      fi

      local i=0
      while shell_running && [ "$i" -lt 25 ]; do
        quickshell -c omde kill >/dev/null 2>&1 || true
        sleep 0.2
        i=$((i + 1))
      done

      if shell_running; then
        echo "omde: shell did not stop" >&2
        return 1
      fi
    }

    case "''${1:-start}" in
      start)
        start
        ;;
      shell)
        shift
        case "''${1:-}" in
          -d | --daemon)
            exec quickshell -c omde -n -d
            ;;
          "")
            start_shell
            ;;
          *)
            echo "omde: unknown shell option: $1" >&2
            exit 2
            ;;
        esac
        ;;
      session)
        exec mango
        ;;
      run)
        shift
        exec quickshell -c omde --no-duplicate "$@"
        ;;
      stop)
        stop_shell
        ;;
      restart)
        if unit_exists; then
          exec systemctl --user restart omde.service
        fi
        stop_shell
        exec "$0" start
        ;;
      status)
        exec systemctl --user status omde.service
        ;;
      logs)
        exec journalctl --user -u omde.service -f
        ;;
      help | -h | --help)
        usage
        ;;
      *)
        echo "omde: unknown command: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
  '';

  meta = {
    inherit version;
    description = "Start and control OMDE";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "omde";
  };
}
