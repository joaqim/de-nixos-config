self: super:

let
  inherit (super) firefox;
  inherit (self) keepassxc /*fetchFirefoxAddon*/;
in
  firefox.override {

    # See https://github.com/mozilla/policy-templates or
    # about:policies#documentation for more possibilities.
    extraPolicies = {
        BackgroundAppUpdate = false; # Disable automatic application update in the background, when the application is not running.
        CaptivePortal = false;
        DisableBuiltinPDFViewer = true; # Considered a security liability
        DisableFirefoxAccounts = true; # Disable Firefox Sync
        DisableFirefoxScreenshots = true; # No screenshots?
        DisableForgetButton = true; # Thing that can wipe history for X time, handled differently
        DisableMasterPasswordCreation = true; # To be determined how to handle master password
        DisableProfileImport = true; # Purity enforcement: Only allow nix-defined profiles
        DisableProfileRefresh = true; # Disable the Refresh Firefox button on about:support and support.mozilla.org
        DisableSetDesktopBackground = true; # Remove the “Set As Desktop Background…” menuitem when right clicking on an image, because Nix is the only thing that can manage the backgroud
        DisablePocket = true;
        DisableTelemetry = true;
        DisableFormHistory = true;
        DisableFirefoxStudies = true;
        DisablePasswordReveal = true;
        DontCheckDefaultBrowser = true; # Stop being attention whore
        HardwareAcceleration = false; # Disabled as it's exposes points for fingerprinting
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false; # Managed by KeepAss instead
        PDFjs = {
          Enabled = false;
          EnablePermissions = false;
        };
        PictureInPicture = {
          Enabled = true;
          Locked = true;
        };
        SanitizeOnShutdown = {
          Cache = true;
          Cookies = false;
          Downloads = true;
          FormData = true;
          History = false;
          Sessions = false;
          SiteSettings = false;
          OfflineApps = true;
          Locked = true;
        };
        SearchEngines = {
          PreventInstalls = true;
          Add = [
            {
              Name = "SearXNG";
              URLTemplate = "http://searx3aolosaf3urwnhpynlhuokqsgz47si4pzz5hvb7uuzyjncl2tid.onion/search?q={searchTerms}";
              Method = "GET"; # GET | POST
              IconURL = "http://searx3aolosaf3urwnhpynlhuokqsgz47si4pzz5hvb7uuzyjncl2tid.onion/favicon.ico";
              # Alias = example;
              Description = "SearX instance ran by tiekoetter.com as onion-service";
              #PostData = name=value&q={searchTerms};
              #SuggestURLTemplate = https =//www.example.org/suggestions/q={searchTerms}
            }
          ];
          Remove = [
            "Amazon.com"
            "Bing"
            "Google"
          ];
          Default = "SearXNG";
        };
        SearchSuggestEnabled = false;
	      ShowHomeButton = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
          # Exceptions = ["https://example.com"]
        };

        DisableAccounts = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
        DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
        SearchBar = "unified"; # alternative: "separate

        EncryptedMediaExtensions = {
          Enabled = true;
          Locked = true;
        };
        ExtensionUpdate = false;

        FirefoxHome = {
          Search = true;
          TopSites = true;
          SponsoredTopSites = false;
          Highlights = true;
          Pocket = false;
          SponsoredPocket = false;
          Snippets = false;
          Locked = true;
        };
        FirefoxSuggests = {
          WebSuggestions = false;
          SponsoredSuggestions = false;
          ImproveSuggest = false;
          Locked = true;
        };
        UserMessaging = {
          ExtensionRecommendations = false; # Don’t recommend extensions while the user is visiting web pages
          FeatureRecommendations = false; # Don’t recommend browser features
          Locked = true; # Prevent the user from changing user messaging preferences
          MoreFromMozilla = false; # Don’t show the “More from Mozilla” section in Preferences
          SkipOnboarding = true; # Don’t show onboarding messages on the new tab page
          UrlbarInterventions = false; # Don’t offer suggestions in the URL bar
          WhatsNew = false; # Remove the “What’s New” icon and menuitem
        };
        UseSystemPrintDialog = true;
        Preferences = let
          lock-false = { Value = false; Status = "locked"; };
          lock-true = { Value = true; Status = "locked"; };
        in {
          "browser.contentblocking.category" = { Value = "strict"; Status = "locked"; };
          "extensions.pocket.enabled" = lock-false;
          "extensions.screenshots.disabled" = lock-true;
          "browser.topsites.contile.enabled" = lock-false;
          "browser.formfill.enable" = lock-false;
          "browser.search.suggest.enabled" = lock-false;
          "browser.search.suggest.enabled.private" = lock-false;
          "browser.urlbar.suggest.searches" = lock-false;
          "browser.urlbar.showSearchSuggestionsFirst" = lock-false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
          "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
          "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
          "browser.newtabpage.activity-stream.showSponsored" = lock-false;
          "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
          # Needed for Firefox to apply the userChrome.css and userContent.css
          # files (which are defined in 'Default' profile.)
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };

    extraPrefs = ''
    '';

    # Note: NixOS 21.11 rejects if this attribute is even defined, when the
    # Firefox is not ESR.
    # Note: If this were non-empty, then manually-installed addons would be
    # disabled, which I think means that addons installed via users'
    # home-manager (e.g. via NUR) would be disabled, which means that addons
    # would not be upgraded to their latest versions because specifying them
    # here requires pinning them to a version unlike with home-manager+NUR where
    # the versions are upgraded.
    # nixExtensions = [
    #   # (fetchFirefoxAddon {
    #   #   name = ""; # Has to be unique!
    #   #   url = "https://addons.mozilla.org/firefox/downloads/.xpi";
    #   #   sha256 = "";
    #   # })
    # ];

    nativeMessagingHosts = [
      keepassxc  # Allow the KeePassXC-Browser extension to communicate, when a user installed it.
    ];
    # Switch profiles via about:profiles page.
      # For options that are available in Home-Manager see
      # https://nix-community.github.io/home-manager/options.html#opt-programs.firefox.profiles
      profiles ={
        Default = {           # choose a profile name; directory is /home/<user>/.mozilla/firefox/Default
          name = "Default";     # name as listed in about:profiles
          id = 0;               # 0 is the default profile; see also option "isDefault"
          isDefault = true;     # can be omitted; true if profile ID is 0
          settings = {          # specify profile-specific preferences here; check about:config for options
            "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
            "browser.startup.homepage" = "https://nixos.org";
            "browser.newtabpage.pinned" = [{
              title = "NixOS";
              url = "https://nixos.org";
            }];

            # Enable letterboxing
            #"privacy.resistFingerprinting" = true;
            "privacy.resistFingerprinting.letterboxing" = true;

            # WebGL TODO(jq): Loss in performance(?) to prevent hardware tracking
            "webgl.disabled" = true;

            "browser.preferences.defaultPerformanceSettings.enabled" = false;
            "layers.acceleration.disabled" = true;
            "privacy.globalprivacycontrol.enabled" = true;

            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

            # "network.trr.mode" = 3;

            # "network.dns.disableIPv6" = false;

            "privacy.donottrackheader.enabled" = true;

            # "privacy.clearOnShutdown.history" = true;
            # "privacy.clearOnShutdown.downloads" = true;
            # "browser.sessionstore.resume_from_crash" = true;

            # See https://librewolf.net/docs/faq/#how-do-i-fully-prevent-autoplay for options
            "media.autoplay.blocking_policy" = 2;


            "signon.management.page.breach-alerts.enabled" = false; # Disable firefox password checking against a breach database
            "network.proxy.socks_remote_dns" = true; # Do DNS lookup through proxy (required for tor to work)
          };

          # Needed with the Tree Style Tab extension, to hide undesired widgets.
          userChrome = ''
            #TabsToolbar {
                visibility: collapse !important;
            }

            #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"] #sidebar-header {
                display: none;
            }
          '';

          # Darker background for new tabs (to not blast eyes with blinding
          # white).
          userContent = ''
            .tab:not(:hover) .closebox {
              display: none;
            }
          '';
        };
      };
  }
