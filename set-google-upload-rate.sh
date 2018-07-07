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
  $SQLITE_CMD "$DATABASE_FILE" <<EOF
update global_preferences set preference_value = $value where preference_type='$pref';
EOF
  }

get_upload_rate() {
  get_global_preference tx
  }

get_download_rate() {
  get_global_preference rx
  }

get_rate() {
  get_global_preference $1
  }

display_current_rates() {
  UPLOAD_RATE=$(get_upload_rate)
  DOWNLOAD_RATE=$(get_download_rate)
  echo "$(date)   Upload rate: $UPLOAD_RATE"
  echo "$(date)   Download rate: $DOWNLOAD_RATE"
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
    echo "$(date) WARNING: Could not identify backup process PID."
    return
  fi
  echo "$(date) Killing process $backup_pid"
  echo "$(date) Process details: $(ps -p $backup_pid | tail -1)"
  kill $backup_pid 2>/dev/null

  count=0
  while true; do
    kill -0 $backup_pid 2>/dev/null || break
    echo "$(date) Waiting for backup process to finish... "
    sleep $RESTART_SLEEP_SECONDS
    count=$(( $count + 1 ))
    [ $count -lt $RESTART_TIMEOUT_COUNT ] || { echo "$(date) ERROR: Backup process did not finish." >&2 ; exit 1 ; }
  done
  }

start_backup_process() {
  echo "$(date) Starting backup and sync application"
  open -a "$BACKUP_APPLICATION_PATH"
  }

restart_backup_process() {
  echo "$(date) Restarting backup and sync application"
  kill_backup_process
  echo -n "$(date) Sleeping ..."
  for i in {1..20}; do
    echo -n "."
    sleep 1
  done
  echo
  start_backup_process
  }

main() {

  while true; do
    case "$1" in

      --current-settings)
        echo "$(date) Current settings"
        display_current_rates
        exit 0
        ;;

      --upload|-u|-tx)
        pref_to_change='tx'
        shift
        new_pref_value=$1
        shift
        ;;

      --download|-d|-rx)
        pref_to_change='rx'
        shift
        new_pref_value=$1
        shift
        ;;

      -*)
        echo "$(date) ERROR: Unknown option \"$1\".  Expected --current-settings, --upload or --download." >&2
        exit 1
        ;;

      *)break
        ;;
    esac
  done

  if [ -z "$pref_to_change" ]; then
    echo "$(date) ERROR: Nothing to do." >&2
    exit 1
  elif [ -z "$new_pref_value" ]; then
    echo "$(date) ERROR: No $pref_to_change value passed." >&2
    exit 1
  fi

  echo "$(date) Current settings:"
  display_current_rates
  echo
  echo "$(date) Setting $pref_to_change to $new_pref_value..."

  set_global_preference $pref_to_change $new_pref_value

  test_value=$(get_rate $pref_to_change)

  if [ ! "$test_value" = "$new_pref_value" ]; then
    echo "$(date) ERROR: Failed to update $pref_to_change value in $DATABASE_FILE." >&2
    exit 1
  fi

  echo
  echo "$(date) New settings:"
  display_current_rates
  echo

  restart_backup_process

  echo
  echo "$(date) Done"
  echo

  }

main $*
