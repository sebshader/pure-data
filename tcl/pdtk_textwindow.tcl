# Copyright (c) 2002-2012 krzYszcz and others.
# For information on usage and redistribution, and for a DISCLAIMER OF ALL
# WARRANTIES, see the file, "LICENSE.txt," in this distribution.  */

# pdtk_textwindow - a window containing scrollable text for "qlist" and
# "textfile" objects - later the latter might get renamed just "text"

# this is adapted from krzYszcz's code for coll in cyclone

package provide pdtk_textwindow 0.1

# these procs are currently all in the global namespace because they're
# called from pd.

proc pdtk_textwindow_open {name geometry title font} {
 if {[winfo exists $name]} {
        $name.text delete 1.0 end
    } else {
        toplevel $name
        wm title $name $title
        wm geometry $name $geometry
        wm protocol $name WM_DELETE_WINDOW \
            [concat pdtk_textwindow_close $name 1]
        bind $name <<Modified>> "pdtk_textwindow_dodirty $name"
        text $name.text -relief raised -highlightthickness 0 -bd 2 \
            -font [get_font_for_size $font] \
            -exportselection 1 -undo 1 \
            -yscrollcommand "$name.scroll set" -background \
            [::pdtk_canvas::get_color text_window_fill $name] \
            -foreground [::pdtk_canvas::get_color text_window_text $name] \
			-insertbackground \
			[::pdtk_canvas::get_color text_window_cursor $name]
        set tmpcol [::pdtk_canvas::get_color text_window_highlight $name]
		if {$tmpcol ne ""} {
			$name.text configure -selectbackground $tmpcol
		}
        scrollbar $name.scroll -command "$name.text yview"
        pack $name.scroll -side right -fill y
        pack $name.text -side left -fill both -expand 1
        bind $name.text <$::modifier-Key-s> "pdtk_textwindow_send $name"
        bind $name.text <$::modifier-Key-w> "pdtk_textwindow_close $name 1"
        bind $name.text <$::modifier-Key-a> "pdtk_textwindow_selectall $name; break"
        bind $name.text <$::modifier-Key-z> "pdtk_textwindow_undo $name; break"
        bind $name.text <$::modifier-Shift-Key-Z> "pdtk_textwindow_redo $name; break"
        bind $name.text <$::modifier-Shift-Key-z> "pdtk_textwindow_redo $name; break"
        focus $name.text
    }
}

proc pdtk_textwindow_dodirty {name} {
    if {[catch {$name.text edit modified} dirty]} {set dirty 1}
    set title [wm title $name]
    set dt [string equal -length 1 $title "*"]
    if {$dirty} {
        if {$dt == 0} {wm title $name *$title}
    } else {
        if {$dt} {wm title $name [string range $title 1 end]}
    }
}

proc pdtk_textwindow_setdirty {name flag} {
    if {[winfo exists $name]} {
        catch {$name.text edit modified $flag}
    }
}

proc pdtk_textwindow_doclose {name} {
    destroy $name
    pdsend [concat $name signoff]
}

proc pdtk_textwindow_append {name contents} {
    if {[winfo exists $name]} {
        $name.text insert end $contents
    }
}

proc pdtk_textwindow_clear {name} {
    if {[winfo exists $name]} {
        $name.text delete 1.0 end
    }
}

proc pdtk_textwindow_send {name} {
    if {[winfo exists $name]} {
        pdsend [concat $name clear]
        for {set i 1} \
         {[$name.text compare $i.end < end]} \
              {incr i 1} {
            set lin [$name.text get $i.0 $i.end]
            if {$lin != ""} {
                set lin [string map {"," " \\, " ";" " \\; " "$" "\\$"} $lin]
                pdsend [concat $name addline $lin]
            }
        }
        pdsend [concat $name notify]
    }
    pdtk_textwindow_setdirty $name 0
}

proc pdtk_textwindow_close {name ask} {
    if {[winfo exists $name]} {
        if {[catch {$name.text edit modified} dirty]} {set dirty 1}
        if {$ask && $dirty} {
            set title [wm title $name]
            if {[string equal -length 1 $title "*"]} {
                set title [string range $title 1 end]
            }
            set answer [tk_messageBox \-type yesnocancel \
             \-icon question \
             \-message [concat Save changes to \"$title\"?]]
            if {$answer == "yes"} {pdtk_textwindow_send $name}
            if {$answer != "cancel"} {pdsend [concat $name close]}
        } else {pdsend [concat $name close]}
    }
}

proc pdtk_textwindow_selectall {name} {
    if {[winfo exists $name]} {
        $name.text tag add sel 1.0 end
        $name.text mark set insert end
    }
}

proc pdtk_textwindow_undo {name} {
    if {[winfo exists $name]} {
        catch {$name.text edit undo}
    }
}

proc pdtk_textwindow_redo {name} {
    if {[winfo exists $name]} {
        catch {$name.text edit redo}
    }
}
