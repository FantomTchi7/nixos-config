{
  my.hardware = {
    amdgpu.enable = true;
    nvidia.enable = true;

    gpuPriority = {
      enable = true;
      primaryPciAddress = null; # e.g. "0000:0b:00.0" for the RX 6900 XT
    };
  };
}
