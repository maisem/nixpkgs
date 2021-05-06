{ lib, buildGoModule, fetchFromGitHub, makeWrapper, iptables, iproute2 }:

buildGoModule rec {
  pname = "tailscale";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "v${version}";
    sha256 = "13p7v8arbrph60ylk4jngi9y614x360a8d2y9d2fwmn4ymnigf5s";
  };

  nativeBuildInputs = [ makeWrapper ];

  CGO_ENABLED = 0;

  vendorSha256 = "0kh7czn763dsdpn5lr9nknirb94s2w4jp0mymy6n5j4l54c4y5rl";

  doCheck = false;

  subPackages = [ "cmd/tailscale" "cmd/tailscaled" ];

  preBuild = ''
    export buildFlagsArray=(
      -tags="xversion"
      -ldflags="-X tailscale.com/version.Long=${version} -X tailscale.com/version.Short=${version}"
    )
  '';

  postInstall = ''
    wrapProgram $out/bin/tailscaled --prefix PATH : ${
      lib.makeBinPath [ iproute2 iptables ]
    }
    sed -i -e "s#/usr/sbin#$out/bin#" -e "/^EnvironmentFile/d" ./cmd/tailscaled/tailscaled.service
    install -D -m0444 -t $out/lib/systemd/system ./cmd/tailscaled/tailscaled.service
  '';

  meta = with lib; {
    homepage = "https://tailscale.com";
    description = "The node agent for Tailscale, a mesh VPN built on WireGuard";
    platforms = platforms.linux;
    license = licenses.bsd3;
    maintainers = with maintainers; [ danderson mbaillie ];
  };
}
