{
  my.hardware = {
    amdgpu.enable = true;
    nvidia.enable = true;

    gpuPriority = {
      enable = true;
      primaryPciAddress = "0000:08:00.0";
    };
  };
}
