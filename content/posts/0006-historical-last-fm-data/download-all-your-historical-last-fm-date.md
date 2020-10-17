---
title: "Download All Your Historical last.fm Data"
date: "2020-10-15"
draft: false
description: "A way to download all your historical last.fm scrobbles with a
simple Python script. Analyse your last.fm history through the ages!"
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
pip3 install -r requirements.txt
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
# initialize url and lists to contain response fields
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

### Make a request to get the number of pages of scrobbles we'll be receiving

```python {linenos=table,linenostart=1}
# make first request, just to get the total number of pages
request_url = url.format(method, username, key, limit, extended, page)
response = requests.get(request_url).json()
total_pages = int(response[method]["@attr"]["totalPages"])
if pages > 0:
    total_pages = min([total_pages, pages])

print("Total pages to retrieve: {}".format(total_pages))
```

### Some objects to store the data in

```python {linenos=table,linenostart=1}
artist_names = []
album_names = []
track_names = []
timestamps = [] # UTC
```

### Make requests one at a time with a gap between to avoid rate limits

```python {linenos=table,linenostart=1}
for page in range(1, int(total_pages) + 1, 1):
    print(
        "\rPage: {}. Estimated time remaining: {} seconds.".format(
            page, 2.5 * int(total_pages - page)
        ),
        end="",
    )
    time.sleep(time_between_requests)
    request_url = url.format(method, username, key, limit, extended, page)
    response = requests.get(request_url)
```

I found that it took about 2.5 seconds per page, so I use that number to get the
estimated runtime of the script. For my user which has 279 pages, each with 200
scrobbles each, the estimated runtime is 695 seconds.

### Parsing the date from last.fm

Now we have a `responses` dictionary containing all the data we want, we can do
some processing on it and grab what we want out of it.

```python {linenos=table,linenostart=1}
if method in response.json():
            response_json = response.json()[method]["track"]
            for track in response_json:
                if "@attr" not in track:
                    artist_names.append(track["artist"][TEXT])
                    album_names.append(track["album"][TEXT])
                    track_names.append(track["name"])
                    timestamps.append(track["date"]["uts"])
```

`method` and `@attr` are to do with currently scrobbling songs. They return a
different structure of Json so I just skip them.

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
```

Finally, we write that data to a CSV and save it to disk:

```python {linenos=table,linenostart=1}
scrobbles = get_scrobbles(page=1, pages=0)  # Default to all Scrobbles
scrobbles.to_csv("./data/lastfm_scrobbles.csv", index=1, encoding="utf-8")
print("{:,} total rows".format(len(scrobbles)))
scrobbles.head()
```

You will now have a populated `data/lastfm_scrobbles.csv` in the repo where you cloned the code.

## Wrapping up

Now you have a CSV containing *all* of your last.fm scrobbles from now back to
when you first started scrobbling.

Here's an excerpt of the CSV I get out:

```txt
,artist,album,track,timestamp,datetime
0,The Hotelier,"Home, Like Noplace Is There",The Scope of All of This Rebuilding,1602839888,2020-10-16 09:18:08
1,The Hotelier,"Home, Like Noplace Is There",An Introduction to the Album,1602838447,2020-10-16 08:54:07
2,Julien Baker,Turn Out the Lights,Appointments,1602797294,2020-10-15 21:28:14
3,Jimi Hendrix,Axis: Bold As Love,Little Wing,1602770967,2020-10-15 14:09:27
4,Jimi Hendrix,Are You Experienced,Hey Joe,1602770757,2020-10-15 14:05:57
5,Mischief Brew,Bacchanal 'N' Philadelphia,Olde Tyme Mem'ry,1602770385,2020-10-15 13:59:45
6,Julien Baker,Turn Out the Lights,Appointments,1602770174,2020-10-15 13:56:14
7,Mischief Brew,Bacchanal 'N' Philadelphia,Every Town Will Celebrate,1602770173,2020-10-15 13:56:13
```

## More ideas

Now you have all your data, you could use `matplotlib` to plot it

{{< figure src="/img/top_scrobbles.png" caption="Don't judge me" width="700px"
height="310px" alt="Top scrobbles">}}

or do something like

```sh
rg "Little Wing" data/lastfm_scrobbles.csv | wc -l
```

to see how many times you've listened to a particular song.

If you want to see the full Python script, it's here:
<https://github.com/mathieuhendey/lastfm_downloader/blob/master/downloader.py>
