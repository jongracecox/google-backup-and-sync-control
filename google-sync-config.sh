#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
GOOGLE_DRIVE_DIR="/Users/jon/Library/Application Support/Google/Drive"
DATABASE_FILE="$GOOGLE_DRIVE_DIR/global.db"
BACKUP_APPLICATION_PATH="/Applications/Backup and Sync.app/Contents/MacOS/Backup and Sync"
RESTART_SLEEP_SECONDS=2
RESTART_TIMEOUT_COUNT=60

SQLITE_CMD=sqlite3

get_global_preference() {
  pref=$1
  $SQLITE_CMD "$DATABASE_FILE" <<EOF
select preference_value from global_preferences where preference_type='$pref';
EOF
  }

set_global_preference() {
  pref=$1
  value=$2
  echo "Setting $pref to $value..."
  $SQLITE_CMD "$DATABASE_FILE" <<EOF
update global_preferences set preference_value = $value where preference_type='$pref';
EOF

  test_value=$(get_global_preference $pref)
  if [ ! "$test_value" = "$value" ]; then
    echo "ERROR: Failed to update $pref value in $DATABASE_FILE." >&2
    exit 1
  fi
  }

display_current_rates() {
  echo ">>> Upload rate: $(get_global_preference tx)"
  echo "<<< Download rate: $(get_global_preference rx)"
}

get_backup_process_pid() {
  ps -ef \
    | grep "$BACKUP_APPLICATION_PATH" \
    | grep -v "grep --color" \
    | awk '{print $2}'
  }

kill_backup_process() {
  backup_pid=$(get_backup_process_pid)
  if [ -z "$backup_pid" ]; then
    echo "WARNING: Could not identify backup process PID."
    return
  fi
  echo "Killing process $backup_pid"
  echo "Process details: $(ps -p $backup_pid | tail -1)"
  kill $backup_pid 2>/dev/null

  count=0
  while true; do
    kill -0 $backup_pid 2>/dev/null || break
    echo "Waiting for backup process to finish... "
    sleep $RESTART_SLEEP_SECONDS
    count=$(( $count + 1 ))
    [ $count -lt $RESTART_TIMEOUT_COUNT ] || { echo "ERROR: Backup process did not finish." >&2 ; exit 1 ; }
  done
  }

start_backup_process() {
  echo "Starting backup and sync application"
  open -a "$BACKUP_APPLICATION_PATH"
  }

restart_backup_process() {
  echo "Restarting backup and sync application"
  kill_backup_process
  echo -n "Sleeping ..."
  for i in {1..20}; do
    echo -n "."
    sleep 1
  done
  echo
  start_backup_process
  echo
  echo "Backup application has been restarted"
  echo
  }

main() {

  echo "Current settings as at $(date):"
  display_current_rates
  echo

  settings_changed=0

  while true; do
    case "$1" in

      --upload|-u|-tx)
        shift
        new_pref_value=$1
        shift
        set_global_preference tx $new_pref_value
        settings_changed=1
        ;;

      --download|-d|-rx)
        shift
        new_pref_value=$1
        shift
        set_global_preference rx $new_pref_value
        settings_changed=1
        ;;

      -*)
        echo "ERROR: Unknown option \"$1\".  Expected --upload or --download." >&2
        exit 1
        ;;

      *)break
        ;;
    esac
  done

  if [ $settings_changed -eq 1 ]; then
    echo
    echo "New settings:"
    display_current_rates
    restart_backup_process
  fi

  }

main $*
