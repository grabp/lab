{
  vmid = 201;
  name = "web-1";

  cores = 2;
  memory = 2048;

  diskSize = 20 * 1024; # MB
  tags = [
    "web"
    "nginx"
    "nixos"
  ];

  net = {
    model = "virtio";
    bridge = "vmbr0";
  };
}
