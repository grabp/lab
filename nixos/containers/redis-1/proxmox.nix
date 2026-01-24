{
  node = "10.0.0.50";
  cores = 1;
  memory = 512;
  rootfs = "local-lvm:4";
  net0 = {
    name = "eth0";
    bridge = "vmbr0";
    ip = "10.0.0.91";
    cidr = 24;
    gw = "10.0.0.1";
  };

  lxc = {
    apparmorProfile = "unconfined";
  };
}
