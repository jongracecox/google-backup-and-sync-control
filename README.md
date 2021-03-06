# Google Backup & Sync Transfer Rate Control for Mac

This script allows you to easily adjust the upload and download rates for Google Backup & Sync
on a scheduled basis.

The script is provided as-is with no warranties.  Use at your own risk.

## Installation

Choose a path for the script to live.  A good chocie might be `/Users/<USER>/Scripts`

Download the script using Terminal application:

```bash
curl https://raw.githubusercontent.com/jongracecox/google-backup-and-sync-control/master/google-sync-config.sh > ~/Scripts/google-sync-config.sh
chmod +x ~/Scripts/google-sync-config.sh
```

## Usage

```
google-sync-config.sh [--upload <rate>] [--download <rate>]
```

The script can be used in the following ways.  For these examples I'm going to assume you are
in the same directory as the downloaded script (e.g. `cd ~/Scripts`).

To get current settings, run the script with no parameters

```
> ./google-sync-config.sh
Current settings as at Sat Jul  7 11:03:02 EDT 2018:
>>> Upload rate: 50
<<< Download rate: 500
```

To set rates use the `--upload` and `--download` options.  They can be used together or individually.  
Rate should be passed as an integer.

```bash
./google-sync-config.sh --upload <rate>
./google-sync-config.sh --download <rate>
./google-sync-config.sh --upload <rate> --download <rate>
```

## Example

```
> /google-sync-config.sh --upload 25 --download 150
Current settings as at Sat Jul  7 11:05:33 EDT 2018:
>>> Upload rate: 50
<<< Download rate: 500

Setting tx to 25...
Setting rx to 150...

New settings:
>>> Upload rate: 25
<<< Download rate: 150
Restarting backup and sync application
Killing process 41860
42307
Process details: 41860 ??         3:52.28 /Applications/Backup and Sync.app/Contents/MacOS/Backup and Sync
Waiting for backup process to finish...
Sleeping .......................
Starting backup and sync application

Backup application has been restarted
```

## Scheduled use

To schedule rate changes you can use crontab on your Mac.  If you're comfortable using `vi` then just use
`crontab -e` to edit your crontab.  If you haven't used vi before then `nano` may be better, so use
`export VISUAL=nano; crontab -e` to edit your crontab settings.

Change `/path/to/script` to the location of your script.

This example will set the following schedule:

| When | What                                  |
| ---- | ------------------------------------- |
| 2am  | Set upload to 100 and download to 200 |
| 7am  | Set upload to 25 and download to 50   |


Run `crontab -e` and paste this into your crontab settings.

```
#  .---------------- minute (0 - 59)
#  |   .------------- hour (0 - 23)
#  |   |   .---------- day of month (1 - 31)
#  |   |   |   .------- month (3 - 12) OR jan,feb,mar,apr ...
#  |   |   |   |  .----- day of week (0 - 6) (Sunday=0 or 7)  OR sun,mon,tue,wed,thu,fri,sat
#  |   |   |   |  |
#  *   *   *   *  *  command to be executed

# Change Google backup and sync upload rate
0 2 * * * /path/to/script/google-sync-config.sh --upload 100 --download 200> /path/to/script/google-sync-config.log 2>&1
0 7 * * * /path/to/script/google-sync-config.sh --upload 25 --download 50> /path/to/script/google-sync-config.log 2>&1
```

If you need to temporarily disable the entries you can comment them out by placing a `#` at the start of each line.

