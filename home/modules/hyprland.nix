{ inputs, pkgs, ...}:

let
  toggleApp = pkgs.writeShellScript "toggle-app" ''
    HYPRCTL="${pkgs.hyprland}/bin/hyprctl"
    GREP="${pkgs.gnugrep}/bin/grep"
    APP_CLASS=$1
    LAUNCH_CMD=$2

    if $HYPRCTL clients | $GREP -q "class: $APP_CLASS"; then
        $HYPRCTL dispatch focuswindow "class:$APP_CLASS"
    else
        $HYPRCTL dispatch exec "$LAUNCH_CMD"
    fi
  '';
in

{

  wayland.windowManager.hyprland = {
    enable = true;
    # set the flake package
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    settings = {

      monitor = [
        ",preferred,auto,auto"
        "eDP-1,preferred,auto,1.6"
      ];

      "$mod" = "SUPER";

      input = {
        touchpad = {
          natural_scroll = true;
          scroll_factor = 0.5;
          clickfinger_behavior = true;
        };
        natural_scroll = false;
      };

      gesture = [
        "3, horizontal, workspace"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        "col.active_border" = "$lavender";
        "col.inactive_border" = "rgba(595959aa)";
        resize_on_border = "false";
        allow_tearing = "false";
        layout = "dwindle";
      };

      decoration = {
          rounding = 5;
          rounding_power = 2;

          active_opacity = 1.0;
          inactive_opacity = 1.0;

          shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
              color = "rgba(1a1a1aee)";
          };

          blur = {
              enabled = true;
              size = 3;
              passes = 1;

              vibrancy = 0.1696;
          };
      };

      animations = {
          enabled = true;

          bezier = [
            "easeOutQuint,   0.23,  1,     0.32, 1"
            "easeInOutCubic, 0.65,  0.05,  0.36, 1"
            "linear,         0,     0,     1,    1"
            "almostLinear,   0.5,   0.5,   0.75, 1"
            "quick,          0.15,  0,     0.1,  1"
            "macEaseOut,     0.15,  0,     0,    1"
            "macEaseIn,      0.42,  0,     1,    1"
            "macScale,       0.175, 0.885, 0.32, 1.275"
          ];

          animation = [
            "global,        1,     10,    default"
            "border,        1,     5.39,  easeOutQuint"
            "windows,       1,     4.79,  macEaseOut"
            "windowsIn,     1,     4.79,  macEaseOut, popin 50%"
            "windowsOut,    1,     2.5,   macEaseOut, popin 30%"
            "fadeIn,        1,     1.73,  almostLinear"
            "fadeOut,       1,     1.46,  almostLinear"
            "fade,          1,     3.03,  quick"
            "layers,        1,     3.81,  easeOutQuint"
            "layersIn,      1,     4,     easeOutQuint, fade"
            "layersOut,     1,     1.5,   linear,       fade"
            "fadeLayersIn,  1,     1.79,  almostLinear"
            "fadeLayersOut, 1,     1.39,  almostLinear"
            "workspaces,    1,     1.94,  almostLinear, slide"
            "workspacesIn,  1,     1.21,  almostLinear, slide"
            "workspacesOut, 1,     1.94,  almostLinear, slide"
            "zoomFactor,    1,     7,     quick"
          ];
      };

      bind = [
        "$mod, I, exec, ${toggleApp} kitty kitty"
        "$mod, G, exec, ${toggleApp} brave-browser brave"
        "$mod, U, exec, ${toggleApp} wechat wechat"

        "$mod, Q, killactive"
        "$mod, l, movefocus, l"
        "$mod, h, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, n, movefocus, d"

        "$mod, F, fullscreen"
        "$mod, space, exec, ags request launcher app"
        "CTRL SHIFT, V, exec, ags request launcher cliphist"

        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        "$mod SHIFT, A, exec, ags request screenshot"
        "$mod SHIFT, L, exec, hyprlock"

        "$mod SHIFT, Q, exit"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ && ags request volume"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && ags request volume"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && ags request volume"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggl && ags request volumee"
        ",XF86MonBrightnessUp, exec, brightnessctl s 5%+ && ags request brightness"
        ",XF86MonBrightnessDown, exec, brightnessctl s 5%- && ags request brightness"
      ];

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        new_status = "master";
      };

      misc = {
        force_default_wallpaper = -1;
        disable_hyprland_logo = false;
      };


      exec-once = [
        "fcitx5 -d"
        "keyd-application-mapper -d"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      ];

      windowrule = [
        "match:xwayland true, match:float true, no_blur on"
        "match:xwayland true, match:float true, border_size 0"
        "match:title Photos and Videos, match:xwayland true, float on"
      ];

      layerrule = [
        # 通知中心 (Notification)
        "blur on, match:namespace notification"
        "ignore_alpha 0.5, match:namespace notification"
        "animation slide right, match:namespace notification"

        # 状态栏 (Bar)
        "blur on, match:namespace bar"
        "blur_popups on, match:namespace bar"
        "ignore_alpha 0.5, match:namespace bar"
      ];

      xwayland = {
        force_zero_scaling = true;
      };

    };
  };
}
