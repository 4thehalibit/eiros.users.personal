{ ... }:
{
  # Upstream eiros default packs "--prefer 'regex'" into a single list element,
  # so systemd's $EARLYOOM_ARGS expansion ends up passing it as one literal
  # argument and earlyoom rejects it. Split into separate list elements.
  config.eiros.system.hardware.earlyoom.extra_args = [
    "--prefer"
    "(^|/)(firefox|chromium|vivaldi)$"
  ];
}
