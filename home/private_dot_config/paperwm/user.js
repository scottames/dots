// -*- mode: gnome-shell -*-

var Meta = imports.gi.Meta;
var Clutter = imports.gi.Clutter;
var St = imports.gi.St;
var Main = imports.ui.main;
var Shell = imports.gi.Shell;

// Extension local imports
var Extension, Me, Tiling, Utils, App, Keybindings, Examples;

function init() {
  // Runs _only_ once on startup

  // Initialize extension imports here to make gnome-shell-reload work
  Extension = imports.misc.extensionUtils.getCurrentExtension();
  Me = Extension.imports.user;
  Tiling = Extension.imports.tiling;
  Utils = Extension.imports.utils;
  Keybindings = Extension.imports.keybindings;
  App = Extension.imports.app;

  Tiling.defwinprop(
    {
      wm_class: "zoom",
      scratch_layer: true,
    },
    {
      wm_class: "gnome-calculator",
      scratch_layer: true,
    },
  );
}

function enable() {
  // Runs on extension reloads, eg. when unlocking the session
}

function disable() {
  // Runs on extension reloads eg. when locking the session (`<super>L).
}
