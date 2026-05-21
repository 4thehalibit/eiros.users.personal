{ config, lib, ... }:
{
  config.eiros.users.vwestberg.mangowc.settings = {
    enable_hotarea = 0;
    ov_tab_mode = 1;
    idleinhibit_ignore_visible = 1;
    edge_scroller_pointer_focus = 0;
    numlockon = 1;

    windowrule = [
      "isfloating:1,width:960,height:720,title:keybinds-popup"
    ];

    tagrule = [
      "id:1,layout_name:scroller"
      "id:2,layout_name:scroller"
      "id:3,layout_name:scroller"
      "id:4,layout_name:scroller"
      "id:5,layout_name:scroller"
      "id:6,layout_name:scroller"
      "id:7,layout_name:scroller"
      "id:8,layout_name:scroller"
      "id:9,layout_name:scroller"
    ];

    env = [
      "GTK_THEME,Adwaita:dark"
    ];

    xkb_rules_layout = "us";
    xkb_rules_model = "pc104";

    monitorrule = [
      # Home: single 4K monitor
      "model:VX3211-4K,width:3840,height:2160,refresh:60,x:0,y:0,scale:1.5"
      # Work: two stacked ViewSonics (DP-10 on top rotated, DP-9 below)
      "name:^DP-10$,width:1920,height:1080,refresh:60,x:0,y:0,scale:1,rr:2"
      "name:^DP-9$,width:1920,height:1080,refresh:60,x:0,y:1080,scale:1"
      # Laptop: default work position (x=1920); exec-once moves to x=2560 at home
      "name:^eDP-1$,width:2560,height:1600,refresh:165,x:1920,y:580,scale:1.6"
    ];

    "exec-once" = [
      "sh -c 'sleep 15 && output=$(wlr-randr | grep VX3211-4K | awk \"{print \\$1}\") && [ -n \"$output\" ] && wlr-randr --output \"$output\" --off && sleep 2 && wlr-randr --output \"$output\" --on && sleep 1 && wlr-randr --output eDP-1 --pos 2560,220'"
    ];
  };

  config.eiros.users.vwestberg.mangowc.keybinds = {
    # Override defaults to match Hyprland/Omarchy muscle memory
    close_window              = { modifier_keys = [ "SUPER" ];        flag_modifiers = [ "s" ]; key_symbol = "w";      mangowc_command = "killclient";           command_arguments = null; };
    launch_terminal           = { modifier_keys = [ "SUPER" ];        flag_modifiers = [ "s" ]; key_symbol = "Return"; mangowc_command = "spawn";                command_arguments = "ghostty"; };
    launch_file_browser       = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "f";      mangowc_command = "spawn";                command_arguments = "nautilus"; };
    launch_browser            = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "Return"; mangowc_command = "spawn";                command_arguments = "vivaldi"; };
    quit_mangowc              = { modifier_keys = [ "SUPER" "CTRL" ]; flag_modifiers = [ "s" ]; key_symbol = "q";      mangowc_command = "quit";                 command_arguments = null; };
    screenshot                = { modifier_keys = [ ];                 flag_modifiers = [ "s" ]; key_symbol = "Print";  mangowc_command = "spawn_shell";          command_arguments = "dms screenshot -d ~/Pictures/Screenshots"; };
    night_mode                = { modifier_keys = [ "SUPER" "CTRL" ]; flag_modifiers = [ "s" ]; key_symbol = "n";      mangowc_command = "spawn_shell";          command_arguments = "dms ipc call night toggle"; };
    wallpaper_carousel_toggle = { modifier_keys = [ "SUPER" ];        flag_modifiers = [ "s" ]; key_symbol = "b";      mangowc_command = "spawn_shell";          command_arguments = "dms ipc wallpaperCarousel toggle"; };

    # Arrow keys instead of hjkl
    switch_focus_left         = { modifier_keys = [ "SUPER" ];        flag_modifiers = [ "s" ]; key_symbol = "Left";  mangowc_command = "focusdir";        command_arguments = "left"; };
    switch_focus_right        = { modifier_keys = [ "SUPER" ];        flag_modifiers = [ "s" ]; key_symbol = "Right"; mangowc_command = "focusdir";        command_arguments = "right"; };
    switch_focus_up           = { modifier_keys = [ "SUPER" ];        flag_modifiers = [ "s" ]; key_symbol = "Up";    mangowc_command = "focusdir";        command_arguments = "up"; };
    switch_focus_down         = { modifier_keys = [ "SUPER" ];        flag_modifiers = [ "s" ]; key_symbol = "Down";  mangowc_command = "focusdir";        command_arguments = "down"; };
    swap_window_left          = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "Left";  mangowc_command = "exchange_client"; command_arguments = "left"; };
    swap_window_right         = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "Right"; mangowc_command = "exchange_client"; command_arguments = "right"; };
    swap_window_up            = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "Up";    mangowc_command = "exchange_client"; command_arguments = "up"; };
    swap_window_down          = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "Down";  mangowc_command = "exchange_client"; command_arguments = "down"; };
    move_window_monitor_left  = { modifier_keys = [ "CTRL" "SHIFT" ]; flag_modifiers = [ "s" ]; key_symbol = "Left";  mangowc_command = "tagmon";   command_arguments = "left,1"; };
    move_window_monitor_right = { modifier_keys = [ "CTRL" "SHIFT" ]; flag_modifiers = [ "s" ]; key_symbol = "Right"; mangowc_command = "tagmon";   command_arguments = "right,1"; };
    move_window_monitor_up    = { modifier_keys = [ "CTRL" "SHIFT" ]; flag_modifiers = [ "s" ]; key_symbol = "Up";    mangowc_command = "tagmon";   command_arguments = "up,1"; };
    move_window_monitor_down  = { modifier_keys = [ "CTRL" "SHIFT" ]; flag_modifiers = [ "s" ]; key_symbol = "Down";  mangowc_command = "tagmon";   command_arguments = "down,1"; };
    focus_monitor_left        = { modifier_keys = [ "SUPER" "ALT" ];  flag_modifiers = [ "s" ]; key_symbol = "Left";  mangowc_command = "focusmon"; command_arguments = "left"; };
    focus_monitor_right       = { modifier_keys = [ "SUPER" "ALT" ];  flag_modifiers = [ "s" ]; key_symbol = "Right"; mangowc_command = "focusmon"; command_arguments = "right"; };
    focus_monitor_up          = { modifier_keys = [ "SUPER" "ALT" ];  flag_modifiers = [ "s" ]; key_symbol = "Up";    mangowc_command = "focusmon"; command_arguments = "up"; };
    focus_monitor_down        = { modifier_keys = [ "SUPER" "ALT" ];  flag_modifiers = [ "s" ]; key_symbol = "Down";  mangowc_command = "focusmon"; command_arguments = "down"; };

    # Match Omarchy app shortcuts
    window_fullscreen  = { modifier_keys = [ "SUPER" ];        flag_modifiers = [ "s" ]; key_symbol = "f";    mangowc_command = "togglemaximizescreen"; command_arguments = null; };
    launch_vivaldi     = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "v";    mangowc_command = "spawn";                command_arguments = "vivaldi"; };
    launch_teams       = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "t";    mangowc_command = "spawn";                command_arguments = "teams-for-linux"; };
    launch_editor      = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "n";    mangowc_command = "spawn";                command_arguments = "code"; };
    launch_cider       = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "m";    mangowc_command = "spawn";                command_arguments = "cider-2"; };
    suspend_system     = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "s";    mangowc_command = "spawn_shell";          command_arguments = "systemctl suspend"; };
    monitor_home       = { modifier_keys = [ "SUPER" ];        flag_modifiers = [ "s" ]; key_symbol = "h";    mangowc_command = "spawn_shell";          command_arguments = "wlr-randr --output eDP-1 --pos 2560,220"; };
    monitor_office     = { modifier_keys = [ "SUPER" ];        flag_modifiers = [ "s" ]; key_symbol = "o";    mangowc_command = "spawn_shell";          command_arguments = "wlr-randr --output eDP-1 --pos 1920,580"; };
    webapp_chatgpt     = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "a";    mangowc_command = "spawn";                command_arguments = "vivaldi --app=https://chatgpt.com"; };
    webapp_email       = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "e";    mangowc_command = "spawn";                command_arguments = "vivaldi --app=https://outlook.office.com"; };
    webapp_youtube     = { modifier_keys = [ "SUPER" "SHIFT" ];flag_modifiers = [ "s" ]; key_symbol = "y";    mangowc_command = "spawn";                command_arguments = "vivaldi --app=https://youtube.com"; };

    # Keybinding cheat sheet
    keybinds_cheatsheet = { modifier_keys = [ "SUPER" ]; flag_modifiers = [ "s" ]; key_symbol = "F1"; mangowc_command = "spawn"; command_arguments = "ghostty --title=keybinds-popup -e keybinds-popup"; };

    # LED matrix brightness
    kbd_brightness_down = { modifier_keys = [ "SUPER" ]; flag_modifiers = [ "s" ]; key_symbol = "F7"; mangowc_command = "spawn_shell"; command_arguments = "kbd-brightness-down"; };
    kbd_brightness_up   = { modifier_keys = [ "SUPER" ]; flag_modifiers = [ "s" ]; key_symbol = "F8"; mangowc_command = "spawn_shell"; command_arguments = "kbd-brightness-up"; };

    # Media controls on Insert/Home/PageUp/Delete/End/PageDown cluster
    media_previous     = { modifier_keys = [ ];flag_modifiers = [ "s" ]; key_symbol = "Insert";  mangowc_command = "spawn_shell"; command_arguments = "playerctl previous"; };
    media_play_pause   = { modifier_keys = [ ];flag_modifiers = [ "s" ]; key_symbol = "Home";    mangowc_command = "spawn_shell"; command_arguments = "playerctl play-pause"; };
    media_next         = { modifier_keys = [ ];flag_modifiers = [ "s" ]; key_symbol = "Prior";   mangowc_command = "spawn_shell"; command_arguments = "playerctl next"; };
    media_vol_down     = { modifier_keys = [ ];flag_modifiers = [ "s" ]; key_symbol = "Delete";  mangowc_command = "spawn_shell"; command_arguments = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"; };
    media_mute         = { modifier_keys = [ ];flag_modifiers = [ "s" ]; key_symbol = "End";     mangowc_command = "spawn_shell"; command_arguments = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; };
    media_vol_up       = { modifier_keys = [ ];flag_modifiers = [ "s" ]; key_symbol = "Next";    mangowc_command = "spawn_shell"; command_arguments = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"; };
  };
}
