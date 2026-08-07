{ lib, ... }:

# GTK 4 ignores gtk-theme-name, so home-manager's gtk4.theme only takes effect
# through a CSS import workaround that breaks libadwaita apps. Stylix already
# writes gtk-4.0/gtk.css from the palette, so nothing is lost by leaving the
# theme unset here.
#
# Forced because Stylix sets gtk4.theme to adw-gtk3 explicitly, to keep the
# behaviour it had before home-manager 26.05 changed the default to null.
# Leaving it set would also have home-manager write its own gtk-4.0/gtk.css on
# top of the one Stylix generates.
{
  gtk.gtk4.theme = lib.mkForce null;
}
