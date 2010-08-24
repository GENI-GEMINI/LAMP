<?php
/*
 +-------------------------------------------------------------------------+
 | Copyright (C) 2004-2009 The Cacti Group                                 |
 |                                                                         |
 | This program is free software; you can redistribute it and/or           |
 | modify it under the terms of the GNU General Public License             |
 | as published by the Free Software Foundation; either version 2          |
 | of the License, or (at your option) any later version.                  |
 |                                                                         |
 | This program is distributed in the hope that it will be useful,         |
 | but WITHOUT ANY WARRANTY; without even the implied warranty of          |
 | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           |
 | GNU General Public License for more details.                            |
 +-------------------------------------------------------------------------+
 | Cacti: The Complete RRDTool-based Graphing Solution                     |
 +-------------------------------------------------------------------------+
 | This code is designed, written, and maintained by the Cacti Group. See  |
 | about.php and/or the AUTHORS file for specific developer information.   |
 +-------------------------------------------------------------------------+
 | http://www.cacti.net/                                                   |
 +-------------------------------------------------------------------------+
*/

/* do NOT run this script through a web browser */
if (!isset($_SERVER["argv"][0]) || isset($_SERVER['REQUEST_METHOD'])  || isset($_SERVER['REMOTE_ADDR'])) {
	die("<br><strong>This script is only meant to run at the command line.</strong>");
}

$no_http_headers = TRUE;
$proceed         = FALSE;

include(dirname(__FILE__) . "/../include/global.php");

/* process calling arguments */
$parms = $_SERVER["argv"];
array_shift($parms);

if (sizeof($parms)) {
	foreach($parms as $parameter) {
		@list($arg, $value) = @explode("=", $parameter);

		switch ($arg) {
		case "--proceed":
			$proceed = TRUE;

			break;
		case "--version":
		case "-V":
		case "-H":
		case "--help":
			display_help();
			exit(0);
		default:
			echo "ERROR: Invalid Argument: ($arg)\n\n";
			display_help();
			exit(1);
		}
	}
}

if ($proceed == FALSE) {
	echo "\nFATAL: You Must Explicitally Instruct This Script to Proceed with the '--proceed' Option\n\n";
	display_help();
	exit -1;
}

/* check ownership of the current base path */
$base_rra_path = $config["rra_path"];
$owner_id      = fileowner($base_rra_path);
$group_id      = filegroup($base_rra_path);

/* turn off the poller */
disable_poller();

$poller_running = shell_exec("ps -ef | grep poller.php | wc -l");
if ($poller_running == "1") {
	/* turn on the poller */
	enable_poller();

	echo "FATAL: The Poller is Currently Running\n";
	exit -4;
}

/* turn on extended paths from in the database */
set_config_option("extended_paths", "on");

/* get the host ids and rrd paths from the poller_item table  */
$rrd_info = db_fetch_assoc("SELECT DISTINCT local_data_id, host_id, rrd_path FROM poller_item");

/* setup some counters */
$done_count   = 0;
$ignore_count = 0;
$warn_count   = 0;

/* scan all poller_items */
foreach ($rrd_info as $info) {
	$new_base_path = "$base_rra_path" . "/" . $info["host_id"];
	$new_rrd_path  = $new_base_path . "/" . $info["local_data_id"] . ".rrd";
	$old_rrd_path  = $info["rrd_path"];

	/* create one subfolder for every host */
	if (!is_dir($new_base_path)) {
		/* see if we can create the dirctory for the new file */
		if (mkdir($new_base_path, 0775)) {
			echo "NOTE: New Directory '$new_base_path' Created for RRD Files\n";
			if ($config["cacti_server_os"] != "win32") {
				if (chown($new_base_path, $owner_id) && chgrp($new_base_path, $group_id)) {
					echo "NOTE: New Directory '$new_base_path' Permissions Set\n";
				} else {
					/* turn on the poller */
					enable_poller();

					echo "FATAL: Could not Set Permissions for Directory '$new_base_path'\n";
					exit -5;
				}
			}
		} else {
			/* turn on the poller */
			enable_poller();

			echo "FATAL: Could NOT Make New Directory '$new_base_path'\n";
			exit -1;
		}
	}

	/* copy the file, update the database and remove the old file */
	if ($old_rrd_path == $new_rrd_path) {
		$ignore_count++;

		echo "NOTE: File '$old_rrd_path' is Already Structured, Ignoring\n";
	} elseif (!file_exists($old_rrd_path)) {
		$warn_count++;

		echo "WARNING: Legacy RRA Path '$old_rrd_path' Does not exist, Skipping\n";

		/* alter database */
		update_database($info);
	} elseif (copy($old_rrd_path, $new_rrd_path)) {
		$done_count++;

		echo "NOTE: Copy Complete for File '" . $info["rrd_path"] . "'\n";
		if ($config["cacti_server_os"] != "win32") {
			if (chown($new_rrd_path, $owner_id) && chgrp($new_rrd_path, $group_id)) {
				echo "NOTE: Permissions set for '$new_rrd_path'\n";
			}else{
				/* turn on the poller */
				enable_poller();

				echo "FATAL: Could not Set Permissions for File '$new_rrd_path'\n";
				exit -6;
			}
		}

		/* alter database */
		update_database($info);

		if (unlink($old_rrd_path)) {
			echo "NOTE: Old File '$old_rrd_path' Removed\n";
		} else {
			/* turn on the poller */
			enable_poller();

			echo "FATAL: Old File '$old_rrd_path' Could not be removed\n";
			exit -2;
		}
	} else {
		/* turn on the poller */
		enable_poller();

		echo "FATAL: Could not Copy RRD File '$old_rrd_path' to '$new_rrd_path'\n";
		exit -3;
	}
}

/* finally re-enable the poller */
enable_poller();

echo "NOTE: Process Complete, '$done_count' Completed, '$warn_count' Skipped, '$ignore_count' Previously Structured\n";

/* update database */
function update_database($info) {
	global $new_rrd_path;

		/* upate table poller_item */
	db_execute("UPDATE poller_item
		SET rrd_path = '$new_rrd_path'
		WHERE local_data_id=" . $info["local_data_id"]);

	/* update table data_template_data */
	db_execute("UPDATE data_template_data
		SET data_source_path='<path_rra>/" . $info["host_id"] . "/" . $info["local_data_id"] . ".rrd'
		WHERE local_data_id=" . $info["local_data_id"]);

	echo "NOTE: Database Changes Complete for File '" . $info["rrd_path"] . "'\n";
}

/* turn on the poller */
function enable_poller() {
	set_config_option('poller_enabled', 'on');
}

/* turn off the poller */
function disable_poller() {
	set_config_option('poller_enabled', '');
}

function display_help() {
	echo "Structured RRA Paths Utility, Copyright 2008 - The Cacti Group\n\n";
	echo "A simple command line utility that converts a Cacti system from using\n";
	echo "legacy RRA paths to using structured RRA paths with the following\n";
	echo "naming convention: <path_rra>/host_id/local_data_id.rrd\n\n";
	echo "This utility is designed for very large Cacti systems.\n\n";
	echo "The utility follows the process below:\n";
	echo "  1) Disables the Cacti Poller\n";
	echo "  2) Checks for a Running Poller.\n\n";
	echo "If it Finds a Running Poller, it will:\n";
	echo "  1) Re-enable the Poller\n";
	echo "  2) Exit\n\n";
	echo "Else, it will:\n";
	echo "  1) Enable Structured Paths in the Console (Settings->Paths)\n\n";
	echo "Then, for Each File, it will:\n";
	echo "  1) Create the Structured Path, if Necessary\n";
	echo "  2) Copy the File to the Strucured Path Using the New Name\n";
	echo "  3) Alter the two Database Tables Required\n";
	echo "  4) Remove the Old File\n\n";
	echo "Once all Files are Complete, it will\n";
	echo "  1) Re-enable the Cacti Poller\n\n";
	echo "If the utility encounters a problem along the way, it will:\n";
	echo "  1) Re-enable the poller\n";
	echo "  2) Exit\n\n";
	echo "usage: structure_rra_paths.php --proceed [--help | -H | --version | -V]\n\n";
}

?>