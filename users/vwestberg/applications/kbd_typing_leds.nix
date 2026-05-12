{ pkgs, ... }:
let
  inputmodule = pkgs.inputmodule-control;
  python = pkgs.python3.withPackages (ps: [ ps.evdev ]);

  brightnessFile = "/run/kbd-leds/brightness";
  defaultBrightness = 40;

  brightnessDown = pkgs.writeShellScriptBin "kbd-brightness-down" ''
    val=$(cat ${brightnessFile} 2>/dev/null || echo ${toString defaultBrightness})
    val=$(( val - 10 ))
    [ $val -lt 5 ] && val=5
    echo $val > ${brightnessFile}
  '';

  brightnessUp = pkgs.writeShellScriptBin "kbd-brightness-up" ''
    val=$(cat ${brightnessFile} 2>/dev/null || echo ${toString defaultBrightness})
    val=$(( val + 10 ))
    [ $val -gt 100 ] && val=100
    echo $val > ${brightnessFile}
  '';

  script = pkgs.writeScript "kbd-typing-leds" ''
    #!${python}/bin/python3
    import evdev, glob, os, subprocess, threading, time, sys

    BACKLIGHT        = "/sys/class/leds/framework_laptop::kbd_backlight/brightness"
    INPUTMODULE      = "${inputmodule}/bin/inputmodule-control"
    BRIGHTNESS_FILE  = "${brightnessFile}"
    DEFAULT_MAX_BL   = ${toString defaultBrightness}
    FADE_STEP        = 3
    FADE_TICK        = 0.03
    IDLE_BL          = 1.5
    IDLE_MATRIX      = 3.0

    brightness    = 0
    last_key_time = 0.0
    char_buf      = []
    pending_text  = None
    lock          = threading.Lock()

    def read_max_bl():
        try:
            with open(BRIGHTNESS_FILE) as f:
                return max(5, min(100, int(f.read().strip())))
        except Exception:
            return DEFAULT_MAX_BL

    CHAR_MAP = {
        'KEY_SPACE': ' ', 'KEY_MINUS': '-', 'KEY_EQUAL': '=',
        'KEY_LEFTBRACE': '[', 'KEY_RIGHTBRACE': ']', 'KEY_SEMICOLON': ';',
        'KEY_APOSTROPHE': "'", 'KEY_COMMA': ',', 'KEY_DOT': '.',
        'KEY_SLASH': '/', 'KEY_BACKSLASH': '\\', 'KEY_GRAVE': '`',
    }

    def key_to_char(name):
        if name.startswith('KEY_') and len(name) == 5:
            return name[4]
        return CHAR_MAP.get(name)

    def find_led_matrices():
        """Find /dev/ttyACM* devices belonging to Framework LED Matrix (32ac:0020)."""
        found = []
        for tty in sorted(glob.glob('/dev/ttyACM*')):
            name = os.path.basename(tty)
            try:
                path = os.path.realpath(f'/sys/class/tty/{name}/device')
                while path and path != '/':
                    vid_file = os.path.join(path, 'idVendor')
                    if os.path.exists(vid_file):
                        with open(vid_file) as f: vid = f.read().strip()
                        with open(os.path.join(path, 'idProduct')) as f: pid = f.read().strip()
                        if vid == '32ac' and pid == '0020':
                            found.append(tty)
                        break
                    path = os.path.dirname(path)
            except Exception:
                pass
        return found

    def write_bl(val):
        try:
            with open(BACKLIGHT, 'w') as f:
                f.write(str(max(0, min(read_max_bl(), int(val)))))
        except OSError:
            pass

    def matrix(*args):
        for dev in LED_MATRICES:
            try:
                subprocess.run(
                    [INPUTMODULE, '--serial-dev', dev, 'led-matrix'] + list(args),
                    timeout=2, capture_output=True,
                )
            except Exception:
                pass

    def matrix_worker():
        global pending_text
        matrix('--brightness', str(read_max_bl()))
        matrix_was_on = False
        while True:
            time.sleep(0.05)
            with lock:
                text  = pending_text
                pending_text = None
                idle  = time.monotonic() - last_key_time
            if text is not None:
                if not matrix_was_on:
                    matrix('--brightness', str(read_max_bl()))
                matrix_was_on = True
                matrix('--string', text)
            elif idle > IDLE_MATRIX and matrix_was_on:
                matrix_was_on = False
                matrix('--brightness', '0')

    def backlight_loop():
        global brightness
        while True:
            time.sleep(FADE_TICK)
            with lock:
                idle = time.monotonic() - last_key_time
                if idle > IDLE_BL and brightness > 0:
                    brightness = max(0, brightness - FADE_STEP)
                    write_bl(brightness)

    def find_keyboard():
        for path in evdev.list_devices():
            dev  = evdev.InputDevice(path)
            caps = dev.capabilities()
            if ('Framework' in dev.name and 'Keyboard' in dev.name
                    and evdev.ecodes.EV_KEY in caps
                    and evdev.ecodes.KEY_A in caps.get(evdev.ecodes.EV_KEY, [])):
                return dev
        return None

    LED_MATRICES = find_led_matrices()
    if not LED_MATRICES:
        print("No Framework LED Matrix modules found, will retry", file=sys.stderr)
        sys.exit(1)

    kbd = find_keyboard()
    if kbd is None:
        print("Framework keyboard not found", file=sys.stderr)
        sys.exit(1)

    threading.Thread(target=matrix_worker,  daemon=True).start()
    threading.Thread(target=backlight_loop, daemon=True).start()

    for event in kbd.read_loop():
        if event.type != evdev.ecodes.EV_KEY or event.value != 1:
            continue

        raw_name = evdev.ecodes.KEY[event.code]
        key_name = raw_name if isinstance(raw_name, str) else raw_name[0]
        char     = key_to_char(key_name)

        with lock:
            last_key_time = time.monotonic()
            brightness    = read_max_bl()
            write_bl(brightness)
            if char is not None:
                char_buf.append(char)
                if len(char_buf) > 5:
                    char_buf.pop(0)
                pending_text = '''.join(char_buf)
  '';
in
{
  # Grant seat user access to LED matrix hidraw + serial devices
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0020", MODE="0660", TAG+="uaccess", GROUP="dialout"
  '';

  environment.systemPackages = [ inputmodule brightnessDown brightnessUp ];

  systemd.services.kbd-typing-leds = {
    description = "Keyboard backlight + LED matrix typing effects";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type             = "simple";
      ExecStart        = "${script}";
      Restart          = "on-failure";
      RestartSec       = "5s";
      RuntimeDirectory = "kbd-leds";
      RuntimeDirectoryMode = "0777";
    };
  };
}
