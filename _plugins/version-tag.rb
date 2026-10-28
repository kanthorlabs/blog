# frozen_string_literal: true

# Injects a short commit SHA badge into every page's `.sidebar-bottom`.
# SHA source: CF_PAGES_COMMIT_SHA (Cloudflare Pages) -> `git rev-parse --short HEAD` (local).

module VersionTag
  def self.sha
    return @sha if defined?(@sha)

    raw = ENV["CF_PAGES_COMMIT_SHA"]
    raw = `git rev-parse --short HEAD 2>/dev/null`.strip if raw.nil? || raw.empty?
    @sha = raw.to_s[0, 7]
  end
end

Jekyll::Hooks.register :site, :pre_render do |site|
  site.config["git_short_sha"] = VersionTag.sha
end

Jekyll::Hooks.register :site, :post_write do |site|
  sha = VersionTag.sha
  next if sha.empty?

  snippet = <<~HTML
    <script>
    (function () {
      var sha = #{sha.to_json};
      function inject() {
        var bottom = document.querySelector('.sidebar-bottom');
        if (!bottom || bottom.querySelector('.sidebar-version')) return;
        var el = document.createElement('span');
        el.className = 'sidebar-version';
        el.textContent = sha;
        el.title = 'Deployed commit';
        el.style.cssText = 'display:block;margin-top:.5rem;font-size:.7rem;opacity:.5;text-align:center;font-family:var(--bs-font-monospace,monospace);';
        bottom.appendChild(el);
      }
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', inject);
      } else {
        inject();
      }
    })();
    </script>
  HTML

  Dir.glob(File.join(site.dest, "**", "*.html")).each do |path|
    html = File.read(path)
    next unless html.include?("</body>")
    next if html.include?("sidebar-version")

    html.sub!("</body>", "#{snippet}</body>")
    File.write(path, html)
  end
end
