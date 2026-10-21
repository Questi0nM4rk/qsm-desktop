import qs.QsmShell.Components as QsmShellComponents
import qs.theme

// The rail's group separator: the library's line, in the band's own weight and
// colour, inset from both walls. It stays a named type because the inset and
// the band width are the rail's facts, not the library's.
//
// Replaces the island pills: a filled pill at 1.29:1 against the band read as
// the same plane it was supposed to lift off.
QsmShellComponents.Divider {
    inset: Theme.railDividerInset
    implicitWidth: Theme.railWidth
    implicitHeight: Theme.space2
    strength: Theme.railDividerOpacity
}
