_:

# GTK 4 ignores gtk-theme-name, so home-manager's gtk4.theme only takes effect
# through a CSS import workaround that breaks libadwaita apps. Stylix already
# writes gtk-4.0/gtk.css from the palette, so nothing is lost by leaving the
# theme unset here, which is home-manager's default from 26.05 onwards.
{
  gtk.gtk4.theme = null;
}
