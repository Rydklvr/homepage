---
title: "Download All Your Historical last.fm Data"
date: "2020-10-15"
draft: false
description: "A way to download all your historical last.fm scrobbles with a
simple Python script. Anaylse your last.fm history through the ages!"
categories:
    - music
tags:
    - Last FM
---

I love [last.fm](https://www.last.fm/user/Mathieuhendey). I'm a bit of a
quantified-self nerd, so if there's data to be gleaned about my habits I'm all
for it.

With that it mind, I set out to download all my historical Last.fm data, but it
turns out there's no way to do so. Foiled! Except their API doesn't seem to care
so much, so let's use that.

The full code for this is available on
[GitHub](https://github.com/mathieuhendey/lastfm_downloader), and I suggest
cloning it first.

**A word of warning: I have 55,646 scrobbles at the time of writing and it took 11m13s, so expect
it to take some time.**

Once you have it cloned, `cd` into the repo and install the requirements with

```python
pip install -r requirements.txt
```

What follows is just an explanation of what is happening.

Forgive my terrible Python, it's not always this bad, I promise.

## Dependencies

We need just a few dependencies for this project, here's my `requirements.txt`:

```txt
pandas
requests
```

`Requests` is self-explanatory, and `pandas` is used for outputting to CSV at the end.

## Authenticating

We'll need an API key, and you generate one at <https://www.last.fm/api/account/create>.

```python {linenos=table,linenostart=1}
lastfm_api_key = None  # Generate your own at https://www.last.fm/api/account/create
lastfm_user_name = None  # Provide your own or someone else's user name

if lastfm_user_name is None or lastfm_api_key is None:
    print(
        """
    You need to generate some creds, see the source code
    """
    )
```

## Snippets from the script

### Method signature

Here is the signature of the method I use to download the scrobbles:

```python {linenos=table,linenostart=1}
def get_scrobbles(
    method="recenttracks",
    username=lastfm_user_name,
    key=lastfm_api_key,
    limit=200,
    extended=0,
    page=1,
    pages=0,
):
    """
    method: api method
    username/key: api credentials
    limit: api lets you retrieve up to 200 records per call
    extended: api lets you retrieve extended data for each track, 0=no, 1=yes
    page: page of results to start retrieving at
    pages: how many pages of results to retrieve. if 0, get as many as api can return.
    """
```

### URL we're going to be hammering

Next we create the URL we're going to use to get our data:

```python {linenos=table,linenostart=1}
    url = (
        "https://ws.audioscrobbler.com/2.0/?method=user.get{}"
        "&user={}"
        "&api_key={}"
        "&limit={}"
        "&extended={}"
        "&page={}"
        "&format=json"
    )
```

### Some objects to store the data in

```python {linenos=table,linenostart=1}
    responses = []
    artist_names = []
    album_names = []
    track_names = []
    timestamps = []  # in UTC
```

### Getting a rough idea of how long this will take (a lot of time)

```python {linenos=table,linenostart=1}
   # make first request, just to get the total number of pages
    request_url = url.format(method, username, key, limit, extended, page)
    response = requests.get(request_url).json()
    total_pages = int(response[method]["@attr"]["totalPages"])
    if pages > 0:
        total_pages = min([total_pages, pages])

    print("Total pages to retrieve: {}".format(total_pages))
```

### Make requests one at a time with a gap between to avoid rate limits

```python {linenos=table,linenostart=1}
    # request each page of data one at a time
    for page in range(1, int(total_pages) + 1, 1):
        print("Page: {}".format(page))
        time.sleep(time_between_requests)
        request_url = url.format(method, username, key, limit, extended, page)
        responses.append(requests.get(request_url))
```

### Parsing the date from last.fm

Now we have a `responses` list containing all the data we want, we can do some processing on it!

```python {linenos=table,linenostart=1}
    # parse the fields out of each scrobble in each page (aka response) of scrobbles
    for response in responses:
        scrobbles = response.json()
        for scrobble in scrobbles[method]["track"]:
            # only retain completed scrobbles (aka, with timestamp and not 'now playing')
            if "date" in scrobble.keys():
                artist_names.append(scrobble["artist"]["#text"])
                album_names.append(scrobble["album"]["#text"])
                track_names.append(scrobble["name"])
                timestamps.append(scrobble["date"]["uts"])
```

### Pandas to create a CSV

And the final step is to create a Pandas dataframe in order to output our data to CSV:

```python {linenos=table,linenostart=1}
    # create and populate a dataframe to contain the data
    df = pd.DataFrame()
    df["artist"] = artist_names
    df["album"] = album_names
    df["track"] = track_names
    df["timestamp"] = timestamps
    # In UTC. Last.fm returns datetimes in the user's locale when they listened
    df["datetime"] = pd.to_datetime(df["timestamp"].astype(int), unit="s")

    return df
```

Finally, we write that data to a CSV and save it to disk:

```python {linenos=table,linenostart=1}
scrobbles = get_scrobbles(pages=0)  # Default to all Scrobbles
scrobbles.to_csv("./data/lastfm_scrobbles.csv", index=1, encoding="utf-8")
print("{:,} total rows".format(len(scrobbles)))
scrobbles.head()
```

You will now have a populated `data/lastfm_scrobbles.csv` in the repo where you cloned the code.

## Wrapping up

Now you have a CSV containing *all* of your last.fm scrobbles from now back to
when you first started scrobbling.

Here's the `head` of the CSV I get out:

```csv
artist,album,track,timestamp,datetime
0,Nirvana,In Utero - 20th Anniversary Remaster,Rape Me,1602591111,2020-10-13 12:11:51
1,Nirvana,In Utero - 20th Anniversary Remaster,Heart-Shaped Box,1602590831,2020-10-13 12:07:11
2,Mischief Brew,Bacchanal 'N' Philadelphia,Devil Of A Time,1602585328,2020-10-13 10:35:28
3,Mischief Brew,Bacchanal 'N' Philadelphia,"Fare Well, Good Fellows",1602585106,2020-10-13 10:31:46
4,Mischief Brew,Bacchanal 'N' Philadelphia,Liberty Unmasked,1602584930,2020-10-13 10:28:50
5,Mischief Brew,Bacchanal 'N' Philadelphia,Dirty Pennies,1602584538,2020-10-13 10:22:18
6,Mischief Brew,Bacchanal 'N' Philadelphia,Boycott Me!,1602584374,2020-10-13 10:19:34
7,Mischief Brew,Bacchanal 'N' Philadelphia,Olde Tyme Mem'ry,1602584074,2020-10-13 10:14:34
8,Mischief Brew,Smash The Windows,Roll Me Through the Gates of Hell,1602583862,2020-10-13 10:11:02
```

If you want to see the full Python script, it's here:
<https://github.com/mathieuhendey/lastfm_downloader/blob/master/downloader.py>
