final: prev: {
  gitFull = prev.gitFull.overrideAttrs (oldAttrs: rec {
    patches = oldAttrs.patches ++ [
      (
        prev.fetchpatch {
          name = "fix-gitk-visibility.patch";
          url = "https://github.com/git/git/commit/1db62e44b7ec93b6654271ef34065b31496cd02e.patch?full_index=1";
          hash = "sha256-ntvnrYFFsJ1Ebzc6vM9/AMFLHMS1THts73PIOG5DkQo=";
        }
      )
    ];
  });
}
