---
title: "Static Blog Aws"
author: Mathieu
date: 2020-10-10T13:24:31+01:00
draft: true
tags:
    - Networking
    - Blogging
    - SSL
---

This blog is a static site generated by [Hugo](https://gohugo.io/). I picked it
for no particular reason, it just seemed like the most popular one at the time.

This post will explain how I got everything hosted on AWS, with:

* SSL
* Redirects from `http://` to  `https://`
* Redirects from `www` subdomain to bare domain

## S3

First, create two S3 buckets. One called the bare domain (in my case
`mathieuhendey.com`), and one with the `www` (`www.mathieuhendey.com`).

Enable "Static website hosting" for both buckets, but for the `www` bucket use
the following settings: (N.B. the protocol: https)

![www redirect image](/img/www_redirect.png)

Now, you have two buckets, one called `website.com` and one called
`www.website.com`. `www.website.com` just redirects to the `wbesite.com` bucket
with https.

## Route 53

Add a hosted zone for your domain, in my case it would be `mathieuhendey.com`,
without the `www`.

Don't worry too much about anything else in here for now.

## Certificate manager

Now open the Certificate Manager service in AWS. **Make sure you choose N.
Virginia as your region**. When we get to the later stage of setting up
Cloudfront distributions, it won't see your certificate if it was created in any
region other than N. Virginia.

Click "Request a certificate", then "Request a public certificate on the next
screen.

Add both the bare domain and the `www.` subdomain.

![www redirect image](/img/certificate_domain_names.png)

On the next screen, choose whichever one you prefer. I chose DNS validation
because since my domain is all managed in AWS it involved no input from me.

Add some tags if you want to, you don't need to. Then click next, review
everything looks correct, and request the certificates.
