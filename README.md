# Event Command

I wrote `ev-cmd` because I didn't have an easy way to bind commands to my [Koolertron macropad](https://www.koolertron.com/koolertron-single-handed-programmable-mechanical-keyboard-with-48-programmable-keys.html). 

## Install

### NixOS

Add this flake as an input to your NixOS configuration flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ev-cmd = {
      url = "github:danhab99/ev-cmd";  # Update with your GitHub path
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ev-cmd, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          environment.systemPackages = [
            ev-cmd.packages.x86_64-linux.default
          ];
        }
      ];
    };
  };
}
```

Or use it directly with `nix run`:

```bash
nix run github:danhab99/ev-cmd -- --help
```

Or install it to your profile:

```bash
nix profile install github:danhab99/ev-cmd
```

### Arch Linux (AUR)

Install from the AUR using

```
yay -S ev-cmd
```

### Build from source

Build using `cargo build --release`

## Usage

### Basic Usage

`ev-cmd` listens to input events from a specified device (like a macropad or keyboard) and executes shell commands when keys are pressed.

```bash
ev-cmd --device-path /dev/input/by-id/YOUR_DEVICE
```

### Command Line Options

```
Options:
  -d, --device-path <DEVICE_PATH>  Path to the input device (required)
  -c, --config-path <CONFIG_PATH>  Path to config file (optional)
  -h, --help                       Print help
```

### Configuration

`ev-cmd` uses a TOML configuration file that maps key codes to shell commands. The program searches for `ev-cmd.toml` in the following locations (in order):

1. Path specified with `--config-path`
2. Current working directory (`./ev-cmd.toml`)
3. User config directory (`~/.config/ev-cmd.toml` on Linux)
4. `/etc/ev-cmd.toml`

#### Configuration File Format

The config file maps evdev key codes to shell commands:

```toml
# Key code = "shell command"
30 = "notify-send 'Key A pressed'"
48 = "firefox"
46 = "alacritty"
32 = "rofi -show drun"
```

#### Finding Key Codes

To find the key codes for your device:

1. List available input devices:
   ```bash
   ls -l /dev/input/by-id/
   ```

2. Run `ev-cmd` with an empty or minimal config to see key codes:
   ```bash
   ev-cmd --device-path /dev/input/by-id/YOUR_DEVICE
   ```
   
3. Press keys on your device - the program will output:
   ```
   Caught keycode 30
   Caught keycode 48
   ```

4. Use these key codes in your config file

### Example Configuration

See `templates/ev-cmd.toml.koolertron-ae-smkd` for a complete example mapping all keys on a Koolertron macropad.

Example config for common tasks:

```toml
# Row 1: Applications
30 = "firefox"
48 = "alacritty"
46 = "code"
32 = "nautilus"

# Row 2: Media controls
35 = "playerctl play-pause"
23 = "playerctl next"
36 = "playerctl previous"
37 = "pactl set-sink-volume @DEFAULT_SINK@ +5%"

# Row 3: System commands
38 = "systemctl suspend"
50 = "loginctl lock-session"
49 = "notify-send 'System Info' \"$(uname -a)\""

# Row 4: Custom scripts
25 = "/home/user/scripts/backup.sh"
16 = "rofi -show run"
```

### Running as a Service

To run `ev-cmd` automatically on system start, create a systemd user service:

```ini
# ~/.config/systemd/user/ev-cmd.service
[Unit]
Description=Event Command Daemon
After=default.target

[Service]
Type=simple
ExecStart=/usr/bin/ev-cmd --device-path /dev/input/by-id/YOUR_DEVICE
Restart=on-failure

[Install]
WantedBy=default.target
```

Enable and start the service:

```bash
systemctl --user enable ev-cmd.service
systemctl --user start ev-cmd.service
```

### Notes

- Only one instance of `ev-cmd` can run at a time (enforced by PID lock)
- Commands are executed in separate threads, so they don't block event processing
- Only key press events (state = 1) trigger commands; key releases are ignored
- Unmapped keys are silently ignored
