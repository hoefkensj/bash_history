#!/usr/bin/env bash
# ############################################################################
# # REPO: bash_History                          AUTHOR: Hoefkens.j@gmail.com #
# # FILE: bash_history.sh                                         2023-04-27 #
# ############################################################################
#

function bash_history_fn() {
    function HELP() {
        echo -e "\nUsage: bash_history [option]\n"
        echo -e "Options:"
        echo -e "  install\tCreate the necessary directories and files for the history tracking"
        echo -e "  clean\t\tRemove the current session's history and reset the command history"
        echo -e "  start\t\tStart a new session and begin tracking commands"
        echo -e "  stop\t\tStop the current session and stop tracking commands"
        echo -e "  show [--all]\tDisplay the command history, use --all to show all history"
        echo -e "  active\tDisplay the history of active sessions"
        echo -e "  orphaned\tDisplay the history of orphaned sessions"
        echo -e "  help\t\tDisplay this help message\n"
        echo -e "Example: bash_history start\n"
    }

	function history_install()	{
		[[ ! -d "$HISTDIR" 			]]	&& install -m 777 -d "$HISTDIR"
		[[ ! -f "$HISTSYSFULL" 		]]	&& install -m 777 /dev/null "$HISTSYSFULL"
		[[ ! -f "$HISTSYSUNIQ"		]]	&& install -m 777 /dev/null "$HISTSYSUNIQ"	
	}
	function history_session_clean()	{
		[[ -f "$HISTSESSION" ]]	&& cat "$HISTSESSION" >> "$HISTSYSFULL"
		install -m 777 /dev/null "$HISTSESSION"
		install -m 777 /dev/null "$HISTFILE"
	}
	function history_session_start()	{
		local STAMP
		$__FNC clean
		STAMP=$( $__FNC stamp)
		echo "$STAMP" >> "$HISTSYSFULL"
		$__FNC uniq "${HISTSYSFULL}" "$($__FNC active)" > "$HISTSYSUNIQ"
		touch $HISTSESSION
		cat $HISTSYSUNIQ >  $HISTFILE
		builtin history -r "$HISTFILE"
	}
	function history_session_stop ()	{
		rm $HISTFILE
		rm $HISTSESSION
	}	
	function history_update()	{
		builtin history -a "$HISTSESSION"
		builtin history -a "$HISTSYSFULL"
		builtin history -c	
		$__FNC uniq "${HISTSYSUNIQ}" "$($__FNC active)" > "$HISTFILE"
		cat "$HISTSESSION" >> "$HISTFILE"
		builtin history -r "$HISTFILE"

	}
	function history_uniq()	{
		tac "$@"| awk '!seen[$0]++'  | tac
		# awk '{ lines[NR] = $0 } END { for(i=NR;i>=1;i--) if(!seen[lines[i]]++) rev[++j] = lines[i]; for(k=j;k>=1;k--) print rev[k] }' "$1" 
	}
	function history_sessions_active ()	{
		ACTIVE=$(pgrep "$(ps -p $$ -o comm=)")
		PATTERN=$(for pid in $ACTIVE; do echo -n "-e .*session\.${pid}.* "; done)
		HISTACTIVE=$(ls $HISTDIR 2>/dev/null | grep $PATTERN)
		for f in $HISTACTIVE; do
			printf '%s ' "$HISTDIR/$f"		
		done
	}
	function history_sessions_orphaned ()	{
		ACTIVE=$(pgrep "$(ps -p $$ -o comm=)")
		PATTERN=$(for pid in $ACTIVE; do echo -n "-e \${pid}\* "; done)
		ORPHANED=$(ls "$HISTDIR/$HISTPFIX.session."* 2>/dev/null | grep -v "$PATTERN")
		for f in $HISTACTIVE; do
			cat "$f"		
		done
	}
	function history_show()	{
		builtin history -c
		[[ "$1" != "--all" ]] && cat "$HISTSYSUNIQ" > "$HISTFILE"
		[[ "$1" == "--all" ]] && cat "$HISTSYSFULL" > "$HISTFILE"
		builtin history -r "$HISTFILE"
		builtin history "$@"
	}
	function history_date_stamp() 	{		
		sep=$( printf '\x1b[%s;%sm############' 1 37)
		dat=$( printf '\x1b[%s;%sm%s' 1 33 "$( date +%Y%m%d )" )
		usr=$( printf '\x1b[%s;%sm%s' 1 36 "$USER" )
		ats=$( printf '\x1b[%s;%sm@' 0 31 )
		hst=$( printf '\x1b[%s;%sm%s' 1 36 "$HOSTNAME" )
		printf '# %s\t%s  ::  %s%s%s\t%s#' "$sep" "$dat" "$usr" "$ats" "$hst" "$sep"
	}
	local __FNC HISTPFIX 
	__FNC=${FUNCNAME[0]}

	case "$1" in
		install) history_install ;;
		clean) history_session_clean ;;
		start) history_session_start ;;
		stop) history_session_stop ;;
		update) history_update ;;
		uniq) shift && history_uniq "$@" ;;
		active) history_sessions_active ;;
		orphaned) history_sessions_orphaned ;;
		show) shift 2 && history_show "$@" ;;
		stamp) history_date_stamp ;;
	esac
}	

bash_history_fn "$@"