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
    import evdev, glob, math, os, subprocess, threading, time, sys

    BACKLIGHT        = "/sys/class/leds/framework_laptop::kbd_backlight/brightness"
    INPUTMODULE      = "${inputmodule}/bin/inputmodule-control"
    BRIGHTNESS_FILE  = "${brightnessFile}"
    DEFAULT_MAX_BL   = ${toString defaultBrightness}
    FADE_STEP        = 3
    FADE_TICK        = 0.03
    IDLE_BL          = 1.5
    IDLE_MATRIX      = 3.0
    PULSE_DECAY      = 4.5   # higher = faster decay
    PULSE_TTL        = 2.0   # seconds before a pulse is discarded

    brightness    = 0
    last_key_time = 0.0
    pulses        = []       # timestamps of recent keypresses
    lock          = threading.Lock()

    def read_max_bl():
        try:
            with open(BRIGHTNESS_FILE) as f:
                return max(5, min(100, int(f.read().strip())))
        except Exception:
            return DEFAULT_MAX_BL

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
        global pulses
        last_brightness = read_max_bl()
        matrix('--brightness', str(last_brightness))
        matrix_was_on = False
        while True:
            time.sleep(0.025)
            now = time.monotonic()
            cur_brightness = read_max_bl()
            with lock:
                idle         = now - last_key_time
                local_pulses = list(pulses)
                pulses       = [pt for pt in pulses if now - pt < PULSE_TTL]
            if cur_brightness != last_brightness:
                last_brightness = cur_brightness
                if matrix_was_on:
                    matrix('--brightness', str(cur_brightness))
            if idle > IDLE_MATRIX:
                if matrix_was_on:
                    matrix_was_on = False
                    matrix('--brightness', '0')
                continue
            level = 0
            for pt in local_pulses:
                age = now - pt
                if age < PULSE_TTL:
                    level = max(level, int(34 * math.exp(-age * PULSE_DECAY)))
            if level > 0:
                if not matrix_was_on:
                    matrix('--brightness', str(cur_brightness))
                    matrix_was_on = True
                matrix('--eq', *([str(level)] * 9))
            elif matrix_was_on:
                matrix('--eq', *(['0'] * 9))

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

        with lock:
            last_key_time = time.monotonic()
            brightness    = read_max_bl()
            write_bl(brightness)
            pulses.append(last_key_time)
            if len(pulses) > 50:
                pulses = pulses[-50:]
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
