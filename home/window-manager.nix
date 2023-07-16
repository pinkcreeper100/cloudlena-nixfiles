{ pkgs, ... }:

{
  # Window manager
  xdg.configFile = {
    "hypr/hyprland.conf".source = ./hyprland/hyprland.conf;
  };

  programs = {
    # Status bar
    waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "custom/tasks" ];
          modules-right = [
            "custom/updates"
            "custom/containers"
            "wireplumber"
            "bluetooth"
            "network"
            "battery"
            "clock"
          ];
          battery = {
            states = {
              warning = 20;
              critical = 1;
            };
            format = "<span size=\"96%\">{icon}</span>";
            format-icons = {
              default = [ "󰁺" "󰁻" "󰁼" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
              charging = [ "󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅" ];
              critical = [ "󱃍" ];
            };
            tooltip-format = "Battery at {capacity}%";
          };
          clock = {
            format = "{:%a %d %b %H:%M}";
            tooltip-format = "<big>{:%B %Y}</big>\n\n<tt><small>{calendar}</small></tt>";
          };
          network = {
            format-ethernet = "󰈀";
            format-wifi = "{icon}";
            format-linked = "󰈀";
            format-disconnected = "󰖪";
            format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
            tooltip-format-wifi = "{essid} at {signalStrength}%";
          };
          wireplumber = {
            format = "<span size=\"120%\">{icon}</span>";
            format-muted = "<span size=\"120%\">󰸈</span>";
            format-icons = [ "󰕿" "󰖀" "󰕾" ];
            tooltip-format = "Volume at {volume}%";
          };
          bluetooth = {
            format = "";
            format-on = "<span size=\"105%\">󰂯</span>";
            format-connected = "<span size=\"105%\">󰂱</span>";
            tooltip-format-on = "Bluetooth {status}";
            tooltip-format-connected = "Connected to {device_alias}";
          };
          "custom/tasks" = {
            exec = pkgs.writeShellScript "waybar-tasks" ''
              set -u

              if [ ! -x "$(command -v task)" ]; then
              	exit 1
              fi

              active_task=$(task rc.verbose=nothing rc.report.activedesc.filter=+ACTIVE rc.report.activedesc.columns:description rc.report.activedesc.sort:urgency- rc.report.activedesc.columns:description activedesc limit:1 | head -n 1)
              if [ -n "$active_task" ]; then
              	echo "󰐌 $active_task"
              	exit 0
              fi

              ready_task=$(task rc.verbose=nothing rc.report.readydesc.filter=+READY rc.report.readydesc.columns:description rc.report.readydesc.sort:urgency- rc.report.readydesc.columns:description readydesc limit:1 | head -n 1)
              if [ -z "$ready_task" ]; then
              	echo ""
              	exit 0
              fi

              echo "󰳟 $ready_task"
            '';
            exec-if = "which task";
            interval = 6;
          };
          "custom/containers" = {
            exec = pkgs.writeShellScript "waybar-containers" ''
              set -u

              if [ ! -x "$(command -v podman)" ]; then
              	exit 1
              fi

              running_container_count=$(podman ps --noheading | wc -l)

              if [ "$running_container_count" -eq 0 ]; then
              	echo ""
              exit 0
              fi

              suffix=""
              if [ "$running_container_count" -gt 1 ]; then
                suffix = "s"
              fi

              echo "{\"text\": \"󰡨\", \"tooltip\": \"$running_container_count container$suffix running\"}"
            '';
            exec-if = "which podman";
            interval = 60;
            return-type = "json";
          };
          "custom/updates" = {
            format = "<span size=\"120%\">{}</span>";
            exec = pkgs.writeShellScript "waybar-updates" ''
              set -u

              current_timestamp=$(nix flake metadata ~/.nixfiles --json | jq '.locks.nodes.nixpkgs.locked.lastModified')
              latest_timestamp=$(nix flake metadata github:NixOS/nixpkgs/nixos-unstable --json | jq '.locked.lastModified')

              if [ "$latest_timestamp" -le "$current_timestamp" ]; then
                echo ""
                exit 0
              fi

              echo "{\"text\": \"󱄅\", \"tooltip\": \"Updates available\"}"
            '';
            exec-if = "test -d ~/.nixfiles";
            interval = 21600; # 6h
            return-type = "json";
          };
        };
      };
      style = ''
        /* General */
        * {
            border-radius: 0;
            font-family: "FiraCode Nerd Font";
            font-size: 13px;
            color: #c0caf5;
          }

          window#waybar {
            background-color: #1a1b26;
          }

          tooltip {
            background-color: #15161e;
          }

          /* Workspaces */
          #workspaces button {
            margin: 4px;
            padding: 0 8px;
            border-radius: 9999px;
          }

          #workspaces button:hover {
            border-color: transparent;
            box-shadow: none;
            background: #414868;
          }

          #workspaces button.focused,
          #workspaces button.active {
            padding: 0 13px;
            background: #2f334d;
          }

          /* Modules */
          #clock,
          #network,
          #wireplumber,
          #bluetooth,
          #battery,
          #custom-updates,
          #custom-tasks,
          #custom-containers,
          #mode {
            margin: 4px;
            padding: 0 13px;
            border-radius: 9999px;
            background-color: #2f334d;
          }

          #network {
            padding: 0 15px 0 11px;
          }

          #mode,
          #custom-updates {
            color: #bb9af7;
            font-weight: bold;
          }

          #battery.critical {
            color: #f7768e;
            font-weight: bold;
          }
      '';
    };

    # Launcher
    wofi = {
      enable = true;
      style = ''
        #window {
          font-family: "Fira Mono";
          background-color: #1a1b26;
          color: #c0caf5;
        }

        #input {
          border-radius: 0;
          border-color: transparent;
          padding: 5px;
          background-color: #1a1b26;
          color: #c0caf5;
        }

        #entry {
          padding: 5px;
        }

        #entry:selected {
          outline: none;
          background-color: #bb9af7;
        }
      '';
    };

    # Lock screen manager
    swaylock = {
      enable = true;
      settings = {
        image = "~/.local/share/wallpapers/bespinian.png";
      };
    };
  };

  services = {
    # Notification daemon
    mako = {
      enable = true;
      font = "Fira Mono 9";
      backgroundColor = "#1a1b26";
      textColor = "#c0caf5";
      borderColor = "#bb9af7";
      defaultTimeout = 8000;
      groupBy = "app-name,summary";
    };

    # Adjust color temperature to reduce eye strain
    gammastep = {
      enable = true;
      provider = "geoclue2";
    };
  };

  home.packages = with pkgs; [
    # Utilities
    brightnessctl
    clipman
    grim
    gron
    playerctl
    slurp
    swaybg
    swayidle
    wf-recorder
    workstyle

    # Fonts
    fira-mono
    lato
    (nerdfonts.override { fonts = [ "FiraCode" ]; })
    noto-fonts-cjk
    noto-fonts-emoji
  ];

  # Wallpaper
  xdg.dataFile = {
    "wallpapers/bespinian.png".source = ./wallpapers/bespinian.png;
  };
}
