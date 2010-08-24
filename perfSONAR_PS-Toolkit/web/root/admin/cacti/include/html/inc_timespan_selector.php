	<script type='text/javascript'>
	// Initialize the calendar
	calendar=null;

	// This function displays the calendar associated to the input field 'id'
	function showCalendar(id) {
		var el = document.getElementById(id);
		if (calendar != null) {
			// we already have some calendar created
			calendar.hide();  // so we hide it first.
		} else {
			// first-time call, create the calendar.
			var cal = new Calendar(true, null, selected, closeHandler);
			cal.weekNumbers = false;  // Do not display the week number
			cal.showsTime = true;     // Display the time
			cal.time24 = true;        // Hours have a 24 hours format
			cal.showsOtherMonths = false;    // Just the current month is displayed
			calendar = cal;                  // remember it in the global var
			cal.setRange(1900, 2070);        // min/max year allowed.
			cal.create();
		}

		calendar.setDateFormat('%Y-%m-%d %H:%M');    // set the specified date format
		calendar.parseDate(el.value);                // try to parse the text in field
		calendar.sel = el;                           // inform it what input field we use

		// Display the calendar below the input field
		calendar.showAtElement(el, "Br");        // show the calendar

		return false;
	}

	// This function update the date in the input field when selected
	function selected(cal, date) {
		cal.sel.value = date;      // just update the date in the input field.
	}

	// This function gets called when the end-user clicks on the 'Close' button.
	// It just hides the calendar without destroying it.
	function closeHandler(cal) {
		cal.hide();                        // hide the calendar
		calendar = null;
	}
</script>
<script type="text/javascript">
<!--

	function applyTimespanFilterChange(objForm) {
		strURL = '?predefined_timespan=' + objForm.predefined_timespan.value;
		strURL = strURL + '&predefined_timeshift=' + objForm.predefined_timeshift.value;
		document.location = strURL;
	}

-->
</script>

	<tr bgcolor="<?php print $colors["panel"];?>" class="noprint">
		<form name="form_timespan_selector" method="post">
		<td class="noprint">
			<table width="100%" cellpadding="0" cellspacing="0">
				<tr>
					<td nowrap style='white-space: nowrap;' width='55'>
						&nbsp;<strong>Presets:</strong>&nbsp;
					</td>
					<td nowrap style='white-space: nowrap;' width='130'>
						<select name='predefined_timespan' onChange="applyTimespanFilterChange(document.form_timespan_selector)">
							<?php
							if ($_SESSION["custom"]) {
								$graph_timespans[GT_CUSTOM] = "Custom";
								$start_val = 0;
								$end_val = sizeof($graph_timespans);
							} else {
								if (isset($graph_timespans[GT_CUSTOM])) {
									asort($graph_timespans);
									array_shift($graph_timespans);
								}
								$start_val = 1;
								$end_val = sizeof($graph_timespans)+1;
							}

							if (sizeof($graph_timespans) > 0) {
								for ($value=$start_val; $value < $end_val; $value++) {
									print "<option value='$value'"; if ($_SESSION["sess_current_timespan"] == $value) { print " selected"; } print ">" . title_trim($graph_timespans[$value], 40) . "</option>\n";
								}
							}
							?>
						</select>
					</td>
					<td nowrap style='white-space: nowrap;' width='30'>
						&nbsp;<strong>From:</strong>&nbsp;
					</td>
					<td width='150' nowrap style='white-space: nowrap;'>
						<input type='text' name='date1' id='date1' title='Graph Begin Timestamp' size='14' value='<?php print (isset($_SESSION["sess_current_date1"]) ? $_SESSION["sess_current_date1"] : "");?>'>
						&nbsp;<input type='image' src='images/calendar.gif' alt='Start date selector' title='Start date selector' border='0' align='absmiddle' onclick="return showCalendar('date1');">&nbsp;
					</td>
					<td nowrap style='white-space: nowrap;' width='20'>
						&nbsp;<strong>To:</strong>&nbsp;
					</td>
					<td width='150' nowrap style='white-space: nowrap;'>
						<input type='text' name='date2' id='date2' title='Graph End Timestamp' size='14' value='<?php print (isset($_SESSION["sess_current_date2"]) ? $_SESSION["sess_current_date2"] : "");?>'>
						&nbsp;<input type='image' src='images/calendar.gif' alt='End date selector' title='End date selector' border='0' align='absmiddle' onclick="return showCalendar('date2');">
					</td>
					<td width='150' nowrap style='white-space: nowrap;'>
						&nbsp;&nbsp;<input type='image' name='move_left' src='images/move_left.gif' alt='Left' border='0' align='absmiddle' title='Shift Left'>
						<select name='predefined_timeshift' title='Define Shifting Interval' onChange="applyTimespanFilterChange(document.form_timespan_selector)">
							<?php
							$start_val = 1;
							$end_val = sizeof($graph_timeshifts)+1;
							if (sizeof($graph_timeshifts) > 0) {
								for ($shift_value=$start_val; $shift_value < $end_val; $shift_value++) {
									print "<option value='$shift_value'"; if ($_SESSION["sess_current_timeshift"] == $shift_value) { print " selected"; } print ">" . title_trim($graph_timeshifts[$shift_value], 40) . "</option>\n";
								}
							}
							?>
						</select>
						<input type='image' name='move_right' src='images/move_right.gif' alt='Right' border='0' align='absmiddle' title='Shift Right'>
					</td>
					<td nowrap style='white-space: nowrap;'>
						&nbsp;&nbsp;<input type='image' name='button_refresh' src='images/button_refresh.gif' alt='Refresh selected time span' border='0' align='absmiddle' value='refresh'>
						<input type='image' name='button_clear' src='images/button_clear.gif' alt='Return to the default time span' border='0' align='absmiddle'>
					</td>
				</tr>
			</table>
		</td>
		</form>
	</tr>