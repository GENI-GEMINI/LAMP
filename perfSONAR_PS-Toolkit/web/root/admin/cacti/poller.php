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

/* we are not talking to the browser */
$no_http_headers = true;

/* start initialization section */
include(dirname(__FILE__) . "/include/global.php");
include_once($config["base_path"] . "/lib/poller.php");
include_once($config["base_path"] . "/lib/data_query.php");
include_once($config["base_path"] . "/lib/graph_export.php");
include_once($config["base_path"] . "/lib/rrd.php");

/* initialize some variables */
$force = FALSE;
$debug = FALSE;

/* process calling arguments */
$parms = $_SERVER["argv"];
array_shift($parms);

if (sizeof($parms)) {
foreach($parms as $parameter) {
	@list($arg, $value) = @explode("=", $parameter);

	switch ($arg) {
	case "-d":
	case "--debug":
		$debug = TRUE;

		break;
	case "--force":
		$force = TRUE;

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

/* record the start time */
list($micro,$seconds) = split(" ", microtime());
$poller_start         = $seconds + $micro;
$overhead_time = 0;

/* get number of polling items from the database */
$poller_interval = read_config_option("poller_interval");

/* retreive the last time the poller ran */
$poller_lastrun = read_config_option('poller_lastrun');

/* get the current cron interval from the database */
$cron_interval = read_config_option("cron_interval");

if ($cron_interval != 60) {
	$cron_interval = 300;
}

/* see if the user wishes to use process leveling */
$process_leveling = read_config_option("process_leveling");

/* retreive the number of concurrent process settings */
$concurrent_processes = read_config_option("concurrent_processes");

/* assume a scheduled task of either 60 or 300 seconds */
if (isset($poller_interval)) {
	$num_polling_items = db_fetch_cell("SELECT COUNT(*) FROM poller_item WHERE rrd_next_step<=0");
	$items_perhost     = array_rekey(db_fetch_assoc("SELECT host_id, COUNT(*) AS data_sources
							FROM poller_item
							WHERE rrd_next_step<=0
							GROUP BY host_id
							ORDER BY host_id"), "host_id", "data_sources");
	$poller_runs       = $cron_interval / $poller_interval;

	define("MAX_POLLER_RUNTIME", $poller_runs * $poller_interval - 2);
}else{
	$num_polling_items = db_fetch_cell("SELECT COUNT(*) FROM poller_item");
	$items_perhost     = array_rekey(db_fetch_assoc("SELECT host_id, COUNT(*) AS data_sources
							FROM poller_item
							GROUP BY host_id
							ORDER BY host_id"), "host_id", "data_sources");
	$poller_runs       = 1;

	define("MAX_POLLER_RUNTIME", 298);
}

if (sizeof($items_perhost)) {
	$items_per_process   = floor($num_polling_items / $concurrent_processes);
}else{
	$process_leveling    = "off";
}

/* some text formatting for platform specific vocabulary */
if ($config["cacti_server_os"] == "unix") {
	$task_type = "Cron";
}else{
	$task_type = "Scheduled Task";
}

if (read_config_option('log_verbosity') >= POLLER_VERBOSITY_MEDIUM) {
	$poller_seconds_sincerun = "never";
	if (isset($poller_lastrun)) {
		$poller_seconds_sincerun = $seconds - $poller_lastrun;
	}

	cacti_log("NOTE: Poller Int: '$poller_interval', $task_type Int: '$cron_interval', Time Since Last: '$poller_seconds_sincerun', Max Runtime '" . MAX_POLLER_RUNTIME. "', Poller Runs: '$poller_runs'", TRUE, "POLLER");;
}

/* our cron can run at either 1 or 5 minute intervals */
if ($poller_interval <= 60) {
	$min_period = "60";
}else{
	$min_period = "300";
}

/* get to see if we are polling faster than reported by the settings, if so, exit */
if ((isset($poller_lastrun) && isset($poller_interval) && $poller_lastrun > 0) && (!$force)) {
	/* give the user some flexibility to run a little moe often */
	if ((($seconds - $poller_lastrun)*1.3) < MAX_POLLER_RUNTIME) {
		if (read_config_option('log_verbosity') >= POLLER_VERBOSITY_MEDIUM) {
			cacti_log("NOTE: $task_type is configured to run too often!  The Poller Interval is '$poller_interval' seconds, with a minimum $task_type period of '$min_period' seconds, but only " . ($seconds - $poller_lastrun) . ' seconds have passed since the poller last ran.', true, 'POLLER');
		}
		exit;
	}
}

/* check to see whether we have the poller interval set lower than the poller is actually ran, if so, issue a warning */
if ((($seconds - $poller_lastrun - 5) > MAX_POLLER_RUNTIME) && ($poller_lastrun > 0)) {
	cacti_log("WARNING: $task_type is out of sync with the Poller Interval!  The Poller Interval is '$poller_interval' seconds, with a maximum of a '300' second $task_type, but " . ($seconds - $poller_lastrun) . ' seconds have passed since the last poll!', true, 'POLLER');
}

db_execute("REPLACE INTO settings (name,value) VALUES ('poller_lastrun'," . $seconds . ')');

/* let PHP only run 1 second longer than the max runtime, plus the poller needs lot's of memory */
ini_set("max_execution_time", MAX_POLLER_RUNTIME + 1);
ini_set("memory_limit", "256M");

$poller_runs_completed = 0;
$poller_items_total    = 0;

while ($poller_runs_completed < $poller_runs) {
	/* record the start time for this loop */
	list($micro,$seconds) = split(" ", microtime());
	$loop_start = $seconds + $micro;

	/* calculate overhead time */
	if ($overhead_time == 0) {
		$overhead_time = $loop_start - $poller_start;
	}

	$polling_hosts = array_merge(array(0 => array("id" => "0")), db_fetch_assoc("SELECT id FROM host WHERE disabled = '' ORDER BY id"));

	/* initialize counters for script file handling */
	$host_count = 1;

	/* initialize file creation flags */
	$change_proc = false;

	/* initialize file and host count pointers */
	$process_number = 0;
	$first_host     = 0;
	$last_host      = 0;

	/* update web paths for the poller */
	db_execute("REPLACE INTO settings (name,value) VALUES ('path_webroot','" . addslashes(($config["cacti_server_os"] == "win32") ? strtr(strtolower(substr(dirname(__FILE__), 0, 1)) . substr(dirname(__FILE__), 1),"\\", "/") : dirname(__FILE__)) . "')");

	/* obtain some defaults from the database */
	$poller      = read_config_option("poller_type");
	$max_threads = read_config_option("max_threads");

	/* initialize poller_time and poller_output tables, check poller_output for issues */
	db_execute("TRUNCATE TABLE poller_time");

	$issues = db_fetch_assoc("SELECT local_data_id, rrd_name FROM poller_output");
	if (sizeof($issues)) {
		$issue_list = "";
		$count = 0;
		foreach($issues as $issue) {
			if ($count <= 20) {
				if ($count == 0) {
					$issue_list .= $issue["rrd_name"] . "(DS[" . $issue["local_data_id"] . "])";
				}else{
					$issue_list .= ", " . $issue["rrd_name"] . "(DS[" . $issue["local_data_id"] . "])";
				}
			}
			$count++;
		}

		if ($count > 20) {
			$issue_list .= ", Additional Issues Remain.  Only showing first 20";
		}

		cacti_log("WARNING: Poller Output Table not Empty.  Issues Found: $count, Data Sources: $issue_list", FALSE, "POLLER");
		db_execute("TRUNCATE TABLE poller_output");
	}

	/* mainline */
	if (read_config_option("poller_enabled") == "on") {
		/* determine the number of hosts to process per file */
		$hosts_per_process = ceil(sizeof($polling_hosts) / $concurrent_processes );

		$items_launched    = 0;

		/* exit poller if spine is selected and file does not exist */
		if (($poller == "2") && (!file_exists(read_config_option("path_spine")))) {
			cacti_log("ERROR: The path: " . read_config_option("path_spine") . " is invalid.  Can not continue", true, "POLLER");
			exit;
		}

		/* Determine Command Name */
		if ($poller == "2") {
			$command_string = read_config_option("path_spine");
			$extra_args     = "";
			$method         = "spine";
			$total_procs    = $concurrent_processes * $max_threads;
			chdir(dirname(read_config_option("path_spine")));
		}else if ($config["cacti_server_os"] == "unix") {
			$command_string = read_config_option("path_php_binary");
			$extra_args     = "-q \"" . $config["base_path"] . "/cmd.php\"";
			$method         = "cmd.php";
			$total_procs    = $concurrent_processes;
		}else{
			$command_string = read_config_option("path_php_binary");
			$extra_args     = "-q \"" . strtolower($config["base_path"] . "/cmd.php\"");
			$method         = "cmd.php";
			$total_procs    = $concurrent_processes;
		}

		/* Populate each execution file with appropriate information */
		foreach ($polling_hosts as $item) {
			if ($host_count == 1) {
				$first_host = $item["id"];
			}

			if ($process_leveling != "on") {
				if ($host_count == $hosts_per_process) {
					$last_host    = $item["id"];
					$change_proc  = true;
				}
			}else{
				if (isset($items_perhost[$item["id"]])) {
					$items_launched += $items_perhost[$item["id"]];
				}

				if (($items_launched >= $items_per_process) ||
					(sizeof($items_perhost) == $concurrent_processes)) {
					$last_host      = $item["id"];
					$change_proc    = true;
					$items_launched = 0;
				}
			}

			$host_count ++;

			if ($change_proc) {
				exec_background($command_string, "$extra_args $first_host $last_host");
				usleep(100000);

				$host_count   = 1;
				$change_proc  = false;
				$first_host   = 0;
				$last_host    = 0;

				$process_number++;
			} /* end change_process */
		} /* end for each */

		/* launch the last process */
		if ($host_count > 1) {
			$last_host = $item["id"];

			exec_background($command_string, "$extra_args $first_host $last_host");
			usleep(100000);

			$process_number++;
		}

		/* insert the current date/time for graphs */
		db_execute("REPLACE INTO settings (name,value) VALUES ('date',NOW())");

		if ($poller == "1") {
			$max_threads = "N/A";
		}

		/* open a pipe to rrdtool for writing */
		$rrdtool_pipe = rrd_init();

		$rrds_processed = 0;
		while (1) {
			$polling_items = db_fetch_assoc("select poller_id,end_time from poller_time where poller_id=0");

			if (sizeof($polling_items) >= $process_number) {
				$rrds_processed = $rrds_processed + process_poller_output($rrdtool_pipe, TRUE);

				log_cacti_stats($loop_start, $method, $concurrent_processes, $max_threads,
					sizeof($polling_hosts), $hosts_per_process, $num_polling_items, $rrds_processed);

				break;
			}else {
				if (read_config_option("log_verbosity") >= POLLER_VERBOSITY_MEDIUM) {
					print "Waiting on " . ($process_number - sizeof($polling_items)) . "/$process_number pollers.\n";
				}

				$rrds_processed = $rrds_processed + process_poller_output($rrdtool_pipe);

				/* end the process if the runtime exceeds MAX_POLLER_RUNTIME */
				if (($poller_start + MAX_POLLER_RUNTIME) < time()) {
					cacti_log("Maximum runtime of " . MAX_POLLER_RUNTIME . " seconds exceeded. Exiting.", true, "POLLER");

					log_cacti_stats($loop_start, $method, $concurrent_processes, $max_threads,
						sizeof($polling_hosts), $hosts_per_process, $num_polling_items, $rrds_processed);

					break;
				}else{
					sleep(1);
				}
			}
		}

		rrd_close($rrdtool_pipe);

		/* process poller commands */
		if (db_fetch_cell("SELECT COUNT(*) FROM poller_command") > 0) {
			$command_string = read_config_option("path_php_binary");
			$extra_args = "-q \"" . $config["base_path"] . "/poller_commands.php\"";
			exec_background($command_string, "$extra_args");
		} else {
			/* no re-index or Rechache present on this run
			 * in case, we have more PCOMMANDS than recaching, this has to be moved to poller_commands.php
			 * but then we'll have to call it each time to make sure, stats are updated */
			db_execute("REPLACE INTO settings (name,value) VALUES ('stats_recache','RecacheTime:0.0 HostsRecached:0')");
		}

		/* graph export */
		if ((read_config_option("export_type") != "disabled") &&
			(read_config_option("export_timing") != "disabled")) {
			$command_string = read_config_option("path_php_binary");
			$extra_args = "-q \"" . $config["base_path"] . "/poller_export.php\"";
			exec_background($command_string, "$extra_args");
		}

		if ($method == "spine") {
			chdir(read_config_option("path_webroot"));
		}
	}else if (read_config_option('log_verbosity') >= POLLER_VERBOSITY_MEDIUM) {
		cacti_log("NOTE: There are no items in your poller for this polling cycle!", TRUE, "POLLER");
	}

	$poller_runs_completed++;

	/* record the start time for this loop */
	list($micro,$seconds) = split(" ", microtime());
	$loop_end = $seconds + $micro;

	if (($loop_end - $loop_start) < $poller_interval) {
		if ($poller_runs_completed == 1) {
			$sleep_time = ($poller_interval - ($loop_end - $loop_start) - $overhead_time);
		}else{
			$sleep_time = ($poller_interval -  ($loop_end - $loop_start));
		}

		/* log some nice debug information */
		if (read_config_option('log_verbosity') >= POLLER_VERBOSITY_DEBUG) {
			echo "Loop  Time is: " . ($loop_end - $loop_start) . "\n";
			echo "Sleep Time is: " . $sleep_time . "\n";
			echo "Total Time is: " . ($loop_end - $poller_start) . "\n";
 		}

		/* sleep the appripriate amount of time */
		if ($poller_runs_completed < $poller_runs) {
			db_close();
			usleep($sleep_time * 1000000);
			db_connect_real($database_hostname, $database_username, $database_password, $database_default, $database_type, $database_port);
		}
	}else if (read_config_option('log_verbosity') >= POLLER_VERBOSITY_MEDIUM) {
		cacti_log("WARNING: Cacti Polling Cycle Exceeded Poller Interval by " . $loop_end-$loop_start-$poller_interval . " seconds", TRUE, "POLLER");
	}
}

function log_cacti_stats($loop_start, $method, $concurrent_processes, $max_threads, $num_hosts,
	$hosts_per_process, $num_polling_items, $rrds_processed) {

	/* take time and log performance data */
	list($micro,$seconds) = split(" ", microtime());
	$loop_end = $seconds + $micro;

	$cacti_stats = sprintf(
		"Time:%01.4f " .
		"Method:%s " .
		"Processes:%s " .
		"Threads:%s " .
		"Hosts:%s " .
		"HostsPerProcess:%s " .
		"DataSources:%s " .
		"RRDsProcessed:%s",
		round($loop_end-$loop_start,4),
		$method,
		$concurrent_processes,
		$max_threads,
		$num_hosts,
		$hosts_per_process,
		$num_polling_items,
		$rrds_processed);

	cacti_log("STATS: " . $cacti_stats ,true,"SYSTEM");

	/* insert poller stats into the settings table */
	db_execute("REPLACE INTO settings (name,value) VALUES ('stats_poller','$cacti_stats')");
}

function display_help() {
	echo "Cacti Poller Version " . db_fetch_cell("SELECT cacti FROM version") . ", Copyright 2004-2009 - The Cacti Group\n\n";
	echo "A simple command line utility to run the Cacti Poller.\n\n";
	echo "usage: poller.php [--force] [--debug|-d]\n\n";
	echo "Options:\n";
	echo "    --force        Override poller overrun detection and force a poller run\n";
	echo "    --debug|-d     Output debug information.  Similar to cacti's DEBUG logging level.\n\n";
}

?>
