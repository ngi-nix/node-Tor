{
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    node-Tor-src = {
      url = "github:Ayms/node-Tor/master";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, node-Tor-src }:
    let
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "i686-linux" "aarch64-linux" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

    in {
      overlays.default = final: prev: {
        node-Tor = with final; stdenv.mkDerivation rec {
          pname = "node-Tor";
          version = "0.0.0";

          src = node-Tor-src;
          buildInputs = [
            nodePackages.browserify
            nodePackages.terser
          ];

          buildPhase = ''
            cd lib
            browserify node-tor.js > ../html/browser.js
            cd ../html
            terser browser.js -c -m -o minified.js
            cd ..
          '';
          installPhase = ''
            # lib/node
            mkdir -p $out/lib/node
            cp -r lib/* $out/lib/node
            mv $out/lib/node/node-tor.js $out/lib/node/node-Tor.js
            cat > $out/lib/node/package.json << EOF
            {
              "name": "${pname}",
              "version": "${version}",
              "license": "MIT",
              "main": "node-Tor.js"
            }
            EOF

            # lib/browser
            mkdir -p $out/lib/browser
            cp html/browser.js $out/lib/browser/node-Tor.js
            cp html/minified.js $out/lib/browser/node-Tor.min.js
          '';
        };
      };

      defaultPackage = forAllSystems (system:
        (import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        }).node-Tor);
    };
}
