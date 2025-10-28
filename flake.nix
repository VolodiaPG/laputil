{
  description = "kernel module of Linux i915 driver with SR-IOV support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;

      # pkgbuildLines = lib.strings.splitString "\n" (builtins.readFile ./PKGBUILD);
      # versionDefinition = lib.lists.findFirst (
      #   line: lib.strings.hasPrefix "pkgver=" line
      # ) "unknown" pkgbuildLines;
      # version = lib.strings.removePrefix "pkgver=" versionDefinition;
      version = "1.0";

      schedModule =
        {
          stdenv,
          nix-gitignore,
          kernel,
        }:
        stdenv.mkDerivation rec {
          inherit version;
          name = "cpufreq-laputil-${version}-${kernel.version}";

          src = lib.cleanSource (
            nix-gitignore.gitignoreSourcePure [
              ./.gitignore
              "result*"
            ] ./.
          );

          hardeningDisable = [
            "pic"
            "format"
          ];
          nativeBuildInputs = kernel.moduleBuildDependencies;

          buildPhase = ''
            sh ./scripts/generate_ac_headers.sh
            make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
              M=$PWD \
              cpufreq_laputil.ko
          '';

          installPhase = ''
            install -D cpufreq_laputil.ko \
              $out/lib/modules/${kernel.modDirVersion}/kernel/cpufreq/cpufreq_laputil.ko
          '';

          meta = {
            platforms = [
              "x86_64-linux"
              "aarch64-linux"
            ];
            insecure = true;
            # description = "Intel i915 driver patched with SR-IOV vGPU functionality";
            # homepage = "https://github.com/strongtz/i915-sriov-dkms";
          };
        };

      testNixosConfiguration = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          (
            { pkgs, modulesPath, ... }:
            {
              imports = [
                "${modulesPath}/profiles/minimal.nix" # reduce NixOS system size
                self.nixosModules.default # include the SR-IOV kernel modules in pkgs
              ];

              # reduce NixOS system size
              nix.enable = false;
              system.switch.enable = false;

              # required for dummy system
              fileSystems."/" = {
                device = "/dev/sda1";
                fsType = "ext4";
              };
              boot = {
                loader.systemd-boot.enable = true;
                kernelPackages = pkgs.linuxPackages_latest;
              };

              system.stateVersion = "25.11"; # do not change, see https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion

              boot.extraModulePackages = [
                pkgs.cpufreq-laputil
              ];

              powerManagement.cpuFreqGovernor = "cpufreq_laputil";

              services.getty.autologinUser = "root";
              users.users.root.password = "";
              virtualisation.vmVariant = {
                # following configuration is added only when building VM with build-vm
                virtualisation = {
                  memorySize = 2048; # Use 2048MiB memory.
                  cores = 3;
                  graphics = false;
                };
              };
            }
          )
        ];
      };
    in
    {
      # builds the drivers
      # this requires a dummy NixOS configuration due to the driver build environment depending on the specific kernel that is used
      checks.aarch64-linux.build-sched-laputil = testNixosConfiguration.config.system.build.toplevel;

      nixosConfigurations.test = testNixosConfiguration;

      # include this NixOS module to include the SR-IOV kernel modules as derivations in your pkgs via an overlay
      nixosModules.default =
        { config, ... }:
        {
          nixpkgs.overlays = [
            (final: prev: {
              cpufreq-laputil = config.boot.kernelPackages.callPackage schedModule { };
            })
          ];
        };
    };
}
