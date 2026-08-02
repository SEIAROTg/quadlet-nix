{
  networking.useDHCP = false;
  networking.firewall.enable = false;
  networking.resolvconf.enable = false;
  environment.etc."resolv.conf".text = "nameserver 127.0.0.1";
  console.enable = false;
}
