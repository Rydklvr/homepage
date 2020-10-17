---
title: "Bundling and Preloading Hugo Assets"
date: "2020-10-16"
draft: false
description: "Bundle, preload, fingerprint, and minify your assets, so they're smaller, and your page loads faster!"
categories:
    - Hugo
tags:
    - asset bundling
    - minification
    - web page improvement
---

With Hugo pipelines[^1] you can now bundle all your assets together, minify them, then fingerprint them for cache-busting. In this post I’ll discuss how I do it for my blog.

## Prerequisites

For any CSS or JS that you want to apply pipelines to, they should go in an
`assets/` directory at the root of your blog.

Here's my directory structure:

```txt
├── LICENSE
├── README.md
├── archetypes
├── assets
├── config.toml
├── content
├── deploy.sh
├── layouts
├── public
├── resources
└── static
```

Within `assets` I have all my JavaScript and CSS that will go through a Hugo
pipeline.

I also have a `links.html` partial, which I'll show further on in this post.

## The code

First we need to get all the assets we'll be bundling. Obviously, you can only
bundle CSS with other CSS and JS with other JS.

```go-html-template {linenos=table,linenostart=1}
{{ $css := resources.Get "css/style.css" }}
{{ $faCss := resources.Get "font-awesome/css/all.css" }}

{{ $faJs := resources.Get "font-awesome/js/all.js" }}
{{ $jquery := resources.Get "lib/jquery/jquery.min.js" }}
{{ $jsMain := resources.Get "js/main.js" }}
```

Now those `$variable`s contain the content of the file.

Next, we put them through a pipeline:

```go-html-template {linenos=table,linenostart=1}
{{ $styleBundle := slice $css $faCss | resources.Concat "css/bundle.css" | resources.Minify | fingerprint}}
{{ $jsBundle := slice $faJs $jquery $jsMain | resources.Concat "js/bundle.js" | resources.Minify | fingerprint}}
```

What this is doing is taking those resources you loaded above, concatenating
them into one file, minifying them, then adding a cache-busting fingerprint, so
your users don't get stuck loading old versions of your JS and CSS assets.

Now I get these files output to my `public` directory, i.e. the static site
itself:

```sh
 /css/bundle.min.d3390533079469783171c47c8f0a85c8185e72b64b0e1cc8f4c6d6b07ed4fa04.css

 /js/bundle.min.579afb61693e2c9faa65f973a858ee520c4ea0ef4f55520a20e8bdcd8758f840.js
```

## Preloading

Now we have all our JS and our CSS bundled, minified and fingerprinted. The next
thing we can do to speed up our site is using preloading. From MDN[^2]:

> The `preload` value of the `<link>` element's `rel` attribute lets you declare fetch requests in the HTML's `<head>`, specifying resources that your page will need very soon, which you want to start loading early in the page lifecycle, before browsers' main rendering machinery kicks in. This ensures they are available earlier and are less likely to block the page's render, improving performance.

In my `links.html` partial I do preloading like this:

```go-html-template {linenos=table,linenostart=1}
<link rel="preload" href="{{ $styleBundle.RelPermalink }}" as="style" onload="this.onload=null;this.rel='stylesheet'">
<link rel="preload" href="{{ $ptSerif.RelPermalink }}" as="font" type="font/ttf" crossorigin="anonymous">
<noscript>
    <link rel="stylesheet" href="{{ $styleBundle.RelPermalink }}">
</noscript>
<link rel="stylesheet" href="{{ $styleBundle.RelPermalink }}">
<script src="{{ $jsBundle.RelPermalink }}" defer></script>
```

On line one we are telling the browser to begin downloading the bundled CSS. And
since we've still got the `$styleBundle` variable in scope, we don't need to
worry about the fingerprint.

That bit of JavaScript in the `onload` event simply changes the `rel` attribute
from `preload` to `stylesheet`. Since the resource has already been downloaded,
we change the `rel` attribute to tell it to start using it instead of
downloading it again.

This won't work if the user has JavaScript turned off, so we just load the
styles regularly inside a `<noscript>` tag.

Notice also that we are using `$styleBundle.RelPermalink`, as without this the
local Hugo server won't work, and you won't see any of your styles.

Here's my full `links.html` partial, which is loaded in my `head.html` partial:

```go-html-template {linenos=table,linenostart=1}
{{ $css := resources.Get "css/style.css" }}
{{ $faCss := resources.Get "font-awesome/css/all.css" }}
{{ $styleBundle := slice $css $faCss | resources.Concat "css/bundle.css" | resources.Minify | fingerprint}}

{{ $faJs := resources.Get "font-awesome/js/all.js" }}
{{ $jquery := resources.Get "lib/jquery/jquery.min.js" }}
{{ $jsMain := resources.Get "js/main.js" }}
{{ $jsBundle := slice $faJs $jquery $jsMain | resources.Concat "js/bundle.js" | resources.Minify | fingerprint}}

{{ $ptSerif := resources.Get "fonts/PT_Serif/PTSerif-Regular.ttf" }}

<link rel="preload" href="{{ $styleBundle.RelPermalink }}" as="style" onload="this.onload=null;this.rel='stylesheet'">
<link rel="preload" href="{{ $ptSerif.RelPermalink }}" as="font" type="font/ttf" crossorigin="anonymous">
<noscript>
    <link rel="stylesheet" href="{{ $styleBundle.RelPermalink }}">
</noscript>
<link rel="stylesheet" href="{{ $styleBundle.RelPermalink }}">
<script src="{{ $jsBundle.RelPermalink }}" defer></script>
```

## Wrapping up

I've seen the minified bundles be as much as 40% smaller than loading each asset
individually and minifying them, so I definitely recommend it if you're trying
to eke out as much performance from your blog as possible.

### Some stats

| Asset | Pre-bundling and minifying | Post-bundling and minifying |
|-------|----------------------------|-----------------------------|
| CSS   | 105K                       | 81K                         |
| JS    | 1.4M                       | 449k                        |

It ends up being fewer network requests, and your page will be
interactive faster because it loads the assets all at once rather than
one-by-one.

I think for my next post I'll look into reducing that `font-awesome.js`...

[^1]: https://gohugo.io/hugo-pipes/
[^2]: https://developer.mozilla.org/en-US/docs/Web/HTML/Preloading_content
