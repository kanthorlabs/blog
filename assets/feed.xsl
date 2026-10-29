<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:atom="http://www.w3.org/2005/Atom">
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <xsl:template match="/atom:feed">
    <html lang="en">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title><xsl:value-of select="atom:title"/> · Feed</title>
        <style>
          :root { color-scheme: light dark; --fg: #222; --muted: #666; --bg: #fff; --border: #e5e5e5; --link: #0a66c2; }
          @media (prefers-color-scheme: dark) { :root { --fg: #ddd; --muted: #999; --bg: #1b1b1e; --border: #333; --link: #6aa9ff; } }
          body { margin: 0 auto; max-width: 720px; padding: 32px 16px; font: 16px/1.6 system-ui, sans-serif; color: var(--fg); background: var(--bg); }
          a { color: var(--link); text-decoration: none; }
          a:hover { text-decoration: underline; }
          .notice { padding: 12px 16px; border: 1px solid var(--border); border-radius: 8px; color: var(--muted); font-size: 14px; }
          .notice code { word-break: break-all; }
          h1 { margin: 24px 0 4px; }
          .subtitle { color: var(--muted); margin: 0 0 24px; }
          article { padding: 16px 0; border-top: 1px solid var(--border); }
          article h2 { margin: 0 0 4px; font-size: 20px; }
          time { color: var(--muted); font-size: 14px; }
          article p { margin: 8px 0 0; }
        </style>
      </head>
      <body>
        <p class="notice">
          This page is an Atom feed. Copy the URL
          <code><xsl:value-of select="atom:link[@rel='self']/@href"/></code>
          into a feed reader to subscribe.
        </p>
        <h1><a href="{atom:link[@rel='alternate']/@href}"><xsl:value-of select="atom:title"/></a></h1>
        <p class="subtitle"><xsl:value-of select="atom:subtitle"/></p>
        <xsl:for-each select="atom:entry">
          <article>
            <h2><a href="{atom:link[@rel='alternate']/@href}"><xsl:value-of select="atom:title"/></a></h2>
            <time datetime="{atom:published}"><xsl:value-of select="substring(atom:published, 1, 10)"/></time>
            <p><xsl:value-of select="atom:summary"/></p>
          </article>
        </xsl:for-each>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
