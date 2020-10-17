---
title: "SEO for Hugo blogs"
author: Mathieu
date: "2020-10-14"
draft: false
description: "Optimise your Hugo blogs SEO!"
tags:
    - SEO
    - web page improvement
categories:
    - Hugo
    - static blog
---

I was recently doing some yak-shaving and decided to improve the SEO of my blog.

There are a lot of `meta` tags that you can add that will improve how search
engines index your blog. I also added some Open Graph Protocol[^1] meta tags.

## config.toml

Make sure your `config.toml` contains at least the required values. You can see
my full `config.toml` on GitHub[^2], but these are the ones you'll need to
recreate my `meta.html` partial.

```toml {linenos=table,linenostart=1}
enableRobotsTXT = true
title = 'Mathieu Hendey'
canonifyURLs = true
[params]
languageCode = 'en-gb'
languageName = 'English'
description = '''I'm a software developer currently working on SIMs and IOT for Arm. Before that I spent a few years working on various UK government projects managed by GDS.'''
author = 'Mathieu Hendey'
github = 'https://github.com/mathieuhendey'
og_image = '/img/og_image.png'
sitename = 'Mathieu Hendey'
twitter = '@mathieu_hendey'
```

## Adding the tags

I recommend creating a `layouts/partials/meta.html` partial, which will be
included in your `head` partial.

### Title tags

Here are the title tags I'm using:

```go-html-template {linenos=table,linenostart=1}
{{/*  Title */}}
<meta property="og:title" content="{{ .Title }} | {{ .Site.Title }}" />
<meta name="twitter:title" content="{{ .Title }} | {{ .Site.Title }}" />
<meta itemprop="name" content="{{ .Title }} | {{ .Site.Title }}" />
<meta name="application-name" content="{{ .Title }} | {{ .Site.Title }}" />
<meta property="og:site_name" content="{{ .Site.Params.sitename }}" />
```

### Description tags

```go-html-template {linenos=table,linenostart=1}
{{/*  Description  */}}
<meta name="description" content="{{ .Site.Params.description }}" />
<meta itemprop="description" content="{{ .Site.Params.description }}" />
<meta property="og:description" content="{{ .Site.Params.description }}" />
<meta name="twitter:description" content="{{ .Site.Params.description }}" />
```

### Permalink tags

```go-html-template {linenos=table,linenostart=1}
{{/*  Permalink  */}}
<base href="{{ .Permalink }}">
<link rel="canonical" href="{{ .Permalink }}" itemprop="url" />
<meta name="url" content="{{ .Permalink }}" />
<meta name="twitter:url" content="{{ .Permalink }}" />
<meta property="og:url" content="{{ .Permalink }}" />
```

### Language tags

```go-html-template {linenos=table,linenostart=1}
{{/*  Language  */}}
<meta property="og:locale" content="{{ .Site.Params.languageCode }}">
<meta name="language" content="{{ .Site.Params.languageName }}">

<meta name="twitter:site" content="{{ .Site.Params.twitter }}">
<meta name="twitter:creator" content="{{ .Site.Params.twitter }}" />
```

## Tags that should only appear in articles

There are some tags that should only appear on article pages. Luckily Hugo has a
way of detecting that you're in an article[^3], and so you can conditionally
insert these tags only on your articles.

If your directory structure matches what Hugo recommend[^4] (i.e., have a
top-level directory under `content`) and then individual directories within,
something like this:

```sh
content
└── posts
    ├── 0001-stowing-dotfiles
    │   └── stowing-dotfiles.md
    ├── 0002-working-from-home
    │   └── working-from-home.md
    ├── 0003-minfiying-css-with-hugo-pipelines
    │   └── minifying-css-with-Hugo-pipelines.md
    ├── 0004-static-ssl-website-aws
    │   └── static-ssl-website-aws.md
    └── 0005-seo-for-hugo
        └── seo-for-hugo.md
```

 you can use a shortcode to detect that you're in an article like this:

```go-html-template {linenos=table,linenostart=1}
{{ if eq .Section "posts" }}
```

Then you can add article-specific tags about things like published time, author
and keywords.

```go-html-template {linenos=table,linenostart=1}
{{ if eq .Section "posts" }}
<meta property="og:type" content="article" />
<meta property="og:article:published_time" content={{ .Date.Format "2006-01-02T15:04:05Z0700" | safeHTML }} />
<meta property="article:published_time" content={{ .Date.Format "2006-01-02T15:04:05Z0700" | safeHTML }} />

{{ with.Params.author }}
<meta property="og:article:author" content="{{humanize . }}" />
<meta property="article:author" content="{{humanize . }}" />
<meta name="author" content="{{humanize . }}" />
{{ end }}

{{ range .Params.categories }}
<meta name="news_keywords" content="{{ index . }}" />
{{ end }}
```

N.B. this will rely on your having some categories listed in your article's
front matter. Here's the front matter for this post for example:

```toml
title: "Seo for Hugo blogs"
author: Mathieu
date: "2020-10-14"
draft: true
tags:
    - Hugo
categories:
    - SEO
```

## Add it to your head.html partial

Now you just need to add your new `meta.html` partial to your `head.html`
partial and get `<meta>` tags inserted where they should be, and improve your
SEO score.

```go-html-template {linenos=table,hl_lines=["5"],linenostart=1}
<head>
  <meta charset="utf-8">
  {{ template "_internal/schema.html" . }}

  {{ partial "meta" . }}

  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="index,all,follow">
  <meta name="googlebot" content="index,follow,snippet,archive">

  {{ template "_internal/opengraph.html" . }}
  
  {{ template "_internal/twitter_cards.html" . }}

  {{ partial "favicon.html" . }}

  {{ if .Site.Params.rss }}
    {{ with .OutputFormats.Get "RSS" }}
      {{ printf `<link href="%s" rel="%s" type="%s" title="%s" />` .Permalink .Rel .MediaType.Type $.Site.Title | safeHTML }}
    {{ end }}
  {{ end }}

  {{ partial "links.html" . }}
</head>
```

## Wrap up

Now your blog will have all the `<meta>` tags you need, and you can use Google
Chrome's Lighthouse tool[^5] to verify how well your site does against its SEO
test. Here are my results:

{{< figure src="/img/lighthouse_100_seo.png" caption="100% SEO score in Lighthouse" width="700px" height="310px" alt="Lighthouse SEO score">}}

There are more tags for Facebook etc., but I don't use those services so did not
include them.

You can find my full `layouts/partials/meta.html` on
[GitHub](https://github.com/mathieuhendey/homepage/blob/main/layouts/partials/meta.html).

[^1]: <https://ogp.me/>
[^2]: <https://github.com/mathieuhendey/homepage/blob/main/config.toml>
[^3]: <https://gohugo.io/content-management/sections/>
[^4]: <https://gohugo.io/content-management/organization/>
[^5]: <https://developers.google.com/web/tools/lighthouse>
