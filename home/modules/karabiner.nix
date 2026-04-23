{ lib, ... }:

let
  hyperModifiers = [ "right_command" "right_control" "right_option" "right_shift" ];

  # 2. 模块化：Caps Lock 映射
  capsLockRule = {
    description = "capsLock to hyper key (control+shift+option+command)";
    manipulators = [{
      type = "basic";
      from = {
        key_code = "caps_lock";
        modifiers.optional = [ "any" ];
      };
      to = [{
        key_code = "right_shift";
        modifiers = [ "right_command" "right_control" "right_option" ];
      }];
      to_if_alone = [{ key_code = "escape"; }];
    }];
  };

  # 3. 模块化：HJKL 方向键
  navigationRules = {
    description = "capsLock + hjkl to arrow";
    manipulators = map (item: {
      type = "basic";
      from = {
        key_code = item.key;
        modifiers.mandatory = hyperModifiers ++ (item.extraFrom or []);
      };
      to = [{
        key_code = item.arrow;
        modifiers = item.extraTo or [];
      }];
    }) [
      { key = "k"; arrow = "up_arrow"; }
      { key = "j"; arrow = "down_arrow"; }
      { key = "h"; arrow = "left_arrow"; }
      { key = "l"; arrow = "right_arrow"; }
      # 带 Command 的方向键
      { key = "k"; arrow = "up_arrow";    extraFrom = ["left_command"]; extraTo = ["left_command"]; }
      { key = "j"; arrow = "down_arrow";  extraFrom = ["left_command"]; extraTo = ["left_command"]; }
      { key = "h"; arrow = "left_arrow";  extraFrom = ["left_command"]; extraTo = ["left_command"]; }
      { key = "l"; arrow = "right_arrow"; extraFrom = ["left_command"]; extraTo = ["left_command"]; }
      # 你可以按需继续通过列表生成控制键/Option键的组合...
    ];
  };

  # 4. 模块化：应用启动
  launchRules = {
    description = "launch application";
    manipulators = map (item: {
      type = "basic";
      from = {
        key_code = item.key;
        modifiers.mandatory = hyperModifiers;
      };
      to = [{ shell_command = "open -a '${item.app}'"; }];
    }) [
      { key = "e"; app = "Finder"; }
      { key = "g"; app = "Brave Browser"; }
      { key = "i"; app = "kitty"; }
      { key = "y"; app = "QQMusic"; }
      { key = "s"; app = "System Preferences"; }
      { key = "u"; app = "WeChat"; }
      { key = "o"; app = "企业微信"; }
      { key = "n"; app = "IntelliJ IDEA Ultimate"; }
      { key = "m"; app = "Emacs"; }
    ];
  };

  # 定义应用 ID 组，方便复用
  apps = {
    browsers = [
      "^com\\.apple\\.Safari$"
      "^com\\.brave\\.Browser$"
      "^org\\.mozilla\\.firefox$"
      "^org\\.mozilla\\.firefoxdeveloperedition$"
      "^com\\.kingsoft\\.wpsoffice\\.mac$"
    ];
    jetbrains = [
      "^com\\.jetbrains\\.intellij$"
      "^com\\.google\\.android\\.studio$"
    ];
    kitty = [ "^net\\.kovidgoyal\\.kitty$" ];
  };

  # ---------------------------------------------------------
  # 新增：Only Specified Application 规则模块
  # ---------------------------------------------------------
  appSpecificRules = {
    description = "Only specified application settings";
    manipulators = [
      # 1. Kitty 专用
      {
        type = "basic";
        from = { key_code = "open_bracket"; modifiers.mandatory = hyperModifiers; };
        to = [{ key_code = "open_bracket"; modifiers = [ "left_control" "left_shift" ]; }];
        conditions = [{ type = "frontmost_application_if"; bundle_identifiers = apps.kitty; }];
      }
      {
        type = "basic";
        from = { key_code = "close_bracket"; modifiers.mandatory = hyperModifiers; };
        to = [{ key_code = "close_bracket"; modifiers = [ "left_control" "left_shift" ]; }];
        conditions = [{ type = "frontmost_application_if"; bundle_identifiers = apps.kitty; }];
      }

      # 2. JetBrains / Android Studio 专用
      {
        type = "basic";
        from = { key_code = "open_bracket"; modifiers.mandatory = hyperModifiers; };
        to = [{ key_code = "open_bracket"; modifiers = [ "left_command" "left_shift" "right_shift" ]; }];
        conditions = [{ type = "frontmost_application_if"; bundle_identifiers = apps.jetbrains; }];
      }
      {
        type = "basic";
        from = { key_code = "close_bracket"; modifiers.mandatory = hyperModifiers; };
        to = [{ key_code = "close_bracket"; modifiers = [ "left_command" "left_shift" "right_shift" ]; }];
        conditions = [{ type = "frontmost_application_if"; bundle_identifiers = apps.jetbrains; }];
      }

      # 3. 浏览器专用 (切换 Tab)
      {
        type = "basic";
        from = { key_code = "open_bracket"; modifiers.mandatory = hyperModifiers; };
        to = [{ key_code = "tab"; modifiers = [ "left_control" "left_shift" ]; }];
        conditions = [{ type = "frontmost_application_if"; bundle_identifiers = apps.browsers; }];
      }
      {
        type = "basic";
        from = { key_code = "close_bracket"; modifiers.mandatory = hyperModifiers; };
        to = [{ key_code = "tab"; modifiers = [ "left_control" ]; }];
        conditions = [{ type = "frontmost_application_if"; bundle_identifiers = apps.browsers; }];
      }
    ];
  };

  baseMapping = {
    description = "base mapping";
    manipulators = [
        # q 的长按映射
        {
          type = "basic";
          from = { key_code = "q"; modifiers = { mandatory = ["left_command"]; optional = ["caps_lock"]; }; };
          to = [ { key_code = "q"; } ];
          to_if_held_down = [ { key_code = "q"; modifiers = ["left_command"]; repeat = false; } ];
        }
        {
          type = "basic";
          from = { key_code = "u"; modifiers.mandatory = hyperModifiers; };
          to = [ { key_code = "u"; modifiers = ["left_control"]; } ];
        }
        {
          type = "basic";
          from = { key_code = "t"; modifiers.mandatory = hyperModifiers; };
          to = [ { key_code = "t"; modifiers = ["left_command"]; } ];
        }
    ];
  };

in
{
  home.file.".config/karabiner/assets/complex_modifications/custom.json".text = builtins.toJSON {
    title = "My Custom Config";
    maintainers =  [ "DengShilin" ];
    rules = [
      capsLockRule
      baseMapping
      appSpecificRules
      navigationRules
      launchRules
    ];
  };
}
