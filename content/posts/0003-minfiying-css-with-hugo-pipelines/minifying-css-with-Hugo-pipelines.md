---
title: "Minifying CSS With Hugo Pipelines"
date: 2020-10-11T12:16:33+01:00
draft: false
author: Mathieu
tags:
    - web page improvement
    - minification
    - Hugo
categories:
    - blogging
---

I was looking at the Google PageSpeed[^1] report for my website as that's
just the kind of thing I get up to on a Sunday, when I noticed that none
of my CSS was minified and it was adding up to a second to page loads.

"This will be easy I thought, surely there's a simple way to do this
out-of-the-box with Hugo". Well, there is a way, but it's not *that* simple.

## Getting set up

First, you need to make sure your CSS assets are in a directory called `assets`, **not**
`static` as some older themes will have them.

You can just rename `static` to `assets` and be done with it.

## Modifying the head partial

This is where you tell Hugo that you want something to be minified.

Here's how I do it in my `head.html` partial:

{{< highlight go-html-template "linenos=table,linenostart=1" >}}
  {{ $css := resources.Get "css/style-light.css" }}
  {{ $style := $css | resources.Minify | fingerprint }}

  <link rel="stylesheet" href="{{ $style.Permalink }}">
{{< / highlight >}}

An explanation:

1. Line one gets the resource from your `assets` folder (remember **not**
   `static`) and assigns it to a variable called `$css`.
2. Line two takes that `$css` variable, pipes into a minification function, and then finally adds a cache-buster.
3. Line four is the `<link rel>` for loading the correctly minified and fingerprinted CSS file.

Now your CSS is minified, and since we've added a cache-buster fingerprint we can make changes to it
without having to wait for Cloudfront to invalidate their cache (more on this in a further blog post).

[^1]: https://developers.google.com/speed/pagespeed/insights/?url=https%3A%2F%2Fmathieuhendey.com%2F2020%2F10%2Fworking-from-home%2F
