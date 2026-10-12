import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.state

// THE shell's search box: the library's text field, plus the two things that
// are this shell's and not a component library's.
//
// 1. The magnifier. Every search surface here starts with one, and a library
//    text field has no opinion about that — a search box is a text box with a
//    glyph in its leading slot, which is exactly why the library stopped
//    shipping a second component for it.
// 2. Who is driving. Typing hands the selection to the KEYBOARD, so a pointer
//    resting mid-list cannot steal it as the results reshuffle underneath.
//    `ShellState` is the shell's own fact; the library reports the typing and
//    refuses to know what it means.
//
// Which KEYS a surface wants is not settled here, because it genuinely differs
// per surface — the launcher wants Left to leave a detail view, the clipboard
// wants Delete to remove an entry, the cheat sheet wants neither. Each surface
// handles `keyPressed` itself and accepts what it takes; everything it leaves
// alone falls through to the field.
QsmShellComponents.TextField {
    onSelectionClaimed: ShellState.claimKeyboardSelection()

    leading: QsmShellComponents.SvgIcon {
        name: "search"
        size: QsmShellStyle.Style.iconMd
        color: QsmShellStyle.Style.textMuted
    }
}
