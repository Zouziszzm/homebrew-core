class Pnpm < Formula
  desc "Fast, disk space efficient package manager"
  homepage "https://pnpm.io/"
  url "https://github.com/pnpm/pnpm/archive/refs/tags/v12.1.0.tar.gz"
  sha256 "3e8718d9c38d61ecdb4aca9df3d1257d11fdfbed4d022d8dbc139f511b5aed66"
  license "MIT"
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :git
  end

  bottle do
    sha256 cellar: :any,                 arm64_tahoe:   "f7a8e74e58eaaab8d4f85e43b8ca4a31077f54083f5b87f4b98e72afa820f403"
    sha256 cellar: :any,                 arm64_sequoia: "f7a8e74e58eaaab8d4f85e43b8ca4a31077f54083f5b87f4b98e72afa820f403"
    sha256 cellar: :any,                 arm64_sonoma:  "f7a8e74e58eaaab8d4f85e43b8ca4a31077f54083f5b87f4b98e72afa820f403"
    sha256 cellar: :any,                 tahoe:         "243f479bf86802dccfe44862b5ddbc43feec74ba975295ffc105661b40f8ff0d"
    sha256 cellar: :any,                 sequoia:       "243f479bf86802dccfe44862b5ddbc43feec74ba975295ffc105661b40f8ff0d"
    sha256 cellar: :any,                 sonoma:        "243f479bf86802dccfe44862b5ddbc43feec74ba975295ffc105661b40f8ff0d"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "482adae72a25632a98d8d39e310f5919d99ee485c6550a8feca330771525bdea"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "482adae72a25632a98d8d39e310f5919d99ee485c6550a8feca330771525bdea"
  end

  depends_on "rust" => :build

  conflicts_with "corepack", because: "both install `pnpm` and `pnpx` binaries"

  # cargo fetches crates from crates.io during the build
  allow_network_access! :build

  def install
    system "cargo", "install", *std_cargo_args(path: "pnpm/crates/cli")

    # Upstream ships these beside the binary as shell scripts rather than
    # symlinks: the `dlx` injection for `pnpx`/`pnx` matches on the name of
    # the resolved `current_exe`, which a symlink would report as `pnpm`.
    (bin/"pn").write <<~SH
      #!/bin/sh
      exec "#{opt_bin}/pnpm" "$@"
    SH
    ["pnpx", "pnx"].each do |name|
      (bin/name).write <<~SH
        #!/bin/sh
        exec "#{opt_bin}/pnpm" dlx "$@"
      SH
    end
    chmod 0755, [bin/"pn", bin/"pnpx", bin/"pnx"]

    generate_completions_from_executable(bin/"pnpm", "completion")
  end

  def caveats
    <<~EOS
      pnpm requires a Node installation to run package scripts. You can install
      one with:
        brew install node
    EOS
  end

  test do
    # `pnpm init` writes a `packageManager` pin naming this exact pnpm, and
    # every later invocation resolves that pin against the registry, so
    # anything that must run without network has to come first.
    assert_match version.to_s, shell_output("#{bin}/pn --version")

    system bin/"pnpm", "init"
    assert_path_exists testpath/"package.json", "package.json must exist"
  end
end
