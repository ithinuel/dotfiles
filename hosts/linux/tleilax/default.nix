{ pkgs, lib, pathRoot, config, inputs, ... }:
let
  mdadmNotify = import ./mdadmNotify.nix { inherit lib pkgs; };
in
{
  imports = [ ./disk.nix ];

  hardware = {
    enableAllFirmware = true;
    nvidia = {
      open = true; # driver open-source officiel NVIDIA
      modesetting.enable = true; # requis pour Wayland
      powerManagement.enable = true; # recommandé
    };
    nvidia-container-toolkit.enable = true;
    bluetooth.settings.General.Experimental = true;
    saleae-logic.enable = true;
    openrazer = {
      enable = true;
      batteryNotifier.enable = true;
    };
    sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
    };
  };
  nixpkgs.config.cudaSupport = true;
  users.users.ithinuel = {
    linger = true;
    extraGroups = [
      "scanner"
      "lp"
      "openrazer"
    ];
  };
  services =
    let
      unstable_pkgs = import inputs.nixpkgs-unstable {
        system = "x86_64-linux";
        config = { allowUnfree = true; cudaSupport = true; };
      };
    in
    {
      hardware.openrgb.enable = true;
      xserver.videoDrivers = [ "nvidia" ];
      gnome.games.enable = true;

      ollama = {
        enable = true;
        package = unstable_pkgs.ollama;
        environmentVariables = {
          OLLAMA_ORIGINS = "https://ollama.home.ithinuel.me";
          OLLAMA_CONTEXT_LENGTH = "196608";
        };
      };
      open-webui = {
        enable = true;
        package = unstable_pkgs.open-webui;
      };
      docling-serve = {
        enable = true;
        package = unstable_pkgs.docling-serve.override {
          withUI = true;
          withRapidocr = true;
          withTesserocr = true;
        };
        environment = {
          DOCLING_NUM_THREADS = "20";
          DOCLING_SERVE_OTEL_ENABLE_METRICS = "False";
          DOCLING_SERVE_OTEL_ENABLE_PROMETHEUS = "False";
          DOCLING_SERVE_ENABLE_UI = "True";
          DOCLING_DEVICE = "cuda";
          TRITON_CACHE_DIR = "/tmp/triton"; # required for torch to use the GPU
          DOCLING_SERVE_MAX_SYNC_WAIT = "600";
          DOCLING_SERVE_DEFAULT_VLM_PRESET = "pixtral";
          PYTORCH_CUDA_ALLOC_CONF = "expandable_segments:True";
          DOCLING_SERVE_ENG_LOC_NUM_WORKERS = "2";
          DOCLING_SERVE_ENG_LOC_SHARE_MODELS = "True";
          DOCLING_SERVE_ALLOW_CUSTOM_VLM_CONFIG = "True";
          DOCLING_SERVE_ALLOWED_VLM_PRESETS = ''["granite_docling", "smoldocling", "pixtral", "deepseek_ocr","gemma_12b", "mypreset"]'';
          DOCLING_SERVE_CUSTOM_VLM_PRESETS = ''
            {
                "mypreset": {
                    "engine": "torch",
                    "model": "gemma4:12b"
                }
            }
          '';
          DOCLING_SERVE_ALLOW_CUSTOM_OCR_CONFIG = "True";
        };
      };
      caddy = {
        enable = true;
        openFirewall = true;
        globalConfig = "debug";
        virtualHosts = {
          "chat.home.ithinuel.me" = {
            extraConfig = ''
              tls ${pathRoot + "/certs/chat.crt"} ${config.sops.secrets.chat-key.path}
              reverse_proxy localhost:8080
            '';
          };
          "docling.home.ithinuel.me" = {
            extraConfig = ''
              tls ${pathRoot + "/certs/docling.crt"} ${config.sops.secrets.docling-key.path}
              reverse_proxy localhost:5001
            '';
          };
          "ollama.home.ithinuel.me" = {
            extraConfig = ''
              tls ${pathRoot + "/certs/ollama.crt"} ${config.sops.secrets.ollama-key.path}
              reverse_proxy localhost:11434 {
                header_up Host localhost:11434
              }
            '';
          };
        };
      };
    };
  # The module doesn't wire up GPU device access — do it manually.
  systemd.services.docling-serve.serviceConfig = {
    SupplementaryGroups = [ "video" "render" ];
    DeviceAllow = [
      "/dev/nvidia0 rw"
      "/dev/nvidiactl rw"
      "/dev/nvidia-uvm rw"
      "/dev/nvidia-uvm-tools rw"
      "/dev/nvidia-modeset rw"
    ];
  };

  boot = {
    # The rest of the RAID settings are populated by disko
    swraid.mdadmConf = ''
      PROGRAM ${mdadmNotify}
    '';

    loader = {
      # Lanzaboote currently replaces the systemd-boot module.
      # This setting is usually set to true in configuration.nix
      # generated at installation time. So we force it to false
      # for now.
      systemd-boot.enable = lib.mkForce false;
      efi = {
        # the primary boot partition
        efiSysMountPoint = "/boot0";
        # Allows the installer to modify EfiVariables (not sure why this’d be needed).
        canTouchEfiVariables = true;
      };
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";

      configurationLimit = 5;

      extraEfiSysMountPoints = [ "/boot1" ]; # Also install Lanzaboote on the secondary boot partition.

      # Auto generate the keys on first boot
      autoGenerateKeys.enable = true;

      # Auto enrole the key in the TPM & autoReboot to activate it
      autoEnrollKeys = {
        enable = true;
        autoReboot = true;
      };
    };

    # transparent ability to run cross build & run other aarch64’s binaries.
    binfmt = {
      emulatedSystems = [ "aarch64-linux" ];
      preferStaticEmulators = false;
    };
  };

  nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";

  sops.secrets = {
    store-key = lib.mkDefault {
      sopsFile = pathRoot + "/secrets/nixbox.store-key.sops";
      format = "binary";
      mode = "0400";
    };
    chat-key = {
      sopsFile = pathRoot + "/secrets/tleilax.chat.cert-key.sops";
      format = "binary";
      owner = config.services.caddy.user;
    };
    docling-key = {
      sopsFile = pathRoot + "/secrets/tleilax.docling.cert-key.sops";
      format = "binary";
      owner = config.services.caddy.user;
    };
    ollama-key = {
      sopsFile = pathRoot + "/secrets/tleilax.ollama.cert-key.sops";
      format = "binary";
      owner = config.services.caddy.user;
    };
  };
  nix.settings = {
    secret-key-files = config.sops.secrets.store-key.path;
    substituters = [
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "tleilax-1:TnLV90m+UmVwKCmz2rqH/ED78OrHFQZ79fnKGHQfGdw="
      "nixbox-1:+RhEM+GSeQmbFCaadAv6fQiuWzAF6f1FW4yuFhfHmYI="
    ];
  };

  programs = {
    ghidra = {
      enable = true;
      gdb = true;
      package = pkgs.ghidra.withExtensions (p: with p; [
        gnudisassembler
      ]);
    };
    pulseview.enable = true;
    steam = {
      enable = true;
      # Translates the X11 Input events into uinput events. Need for using Steam Input in Wayland.
      extest.enable = true;
    };
    coolercontrol.enable = true;
  };

  environment.systemPackages = [
    pkgs.blender
  ];

  virtualisation.virtualbox.host.enable = true;

  security.pki.certificateFiles = [ (pathRoot + "/certs/ithinuel.local.crt") ];
  desktop.enable = true;
}
