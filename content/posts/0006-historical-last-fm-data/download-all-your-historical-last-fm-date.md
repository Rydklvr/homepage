---
title: "Download all your historical last.fm data"
date: "2020-10-15"
draft: false
description: "A way to download all your historical last.fm scrobbles with a
simple Python script. Analyse your last.fm history through the ages!"
categories:
    - music
    - matplotlib
    - parallel processing
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
pandas~=0.25.2
requests~=2.22.0

matplotlib~=3.3.2
requests_toolbelt
```

`Requests`[^1]
: for making REST requests

`pandas`[^2]
: for creating a dataframe and outputting to CSV at the end

`matplotlib`[^3]
: for creating our plot

`requests_toolbelt`[^4]
: for making our API requests in a thread pool

## Authenticating

We'll need an API key, and you generate one at <https://www.last.fm/api/account/create>.
If you don't provide any credentials the script will exit with an error message.

```python {linenos=table,linenostart=15}
if LASTFM_USER_NAME is None or LASTFM_API_KEY is None:
    print(
        """
        You need to generate some credentials, see the source code
        """
    )
    sys.exit(1)
```

## Snippets from the script

### Method signature

Here is the signature of the method I use to download the scrobbles:

```python {linenos=table,linenostart=24}
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


### Make a request to get the number of pages of scrobbles we'll be receiving

```python {linenos=table,linenostart=43}
    url = (
        "https://ws.audioscrobbler.com/2.0/?method=user.get{}"
        "&user={}"
        "&api_key={}"
        "&limit={}"
        "&extended={}"
        "&page={}"
        "&format=json"
    )
    
    # get total number of pages
    request_url = url.format(endpoint, username, key, limit, extended, page)
    response = requests.get(request_url).json()
    total_pages = int(response[endpoint]["@attr"]["totalPages"])
```

### Estimating the total time

This is fairly innacurate because of network speed, last.fm's API performance, computer performance
etc., but I try to calculate the estimated time and it's usually fairly accurate.

```python {linenos=table,linenostart=12}
ESTIMATED_TIME_FOR_PROCESSING_PAGE = 352 # millis
ESTIMATED_TIME_FOR_PROCESSING_DATAFRAME_PER_PAGE_OF_RESULTS = 275 # mills
```

```python {linenos=table,linenostart=60}
    print(
        "Total pages to retrieve: {}. Estimated time: {}".format(
            total_pages, get_time_remaining(total_pages)
        )
    )
```

and the definition of `get_time_remaining()`

```python {linenos=table,linenostart=99}
def get_time_remaining(pages_remaining):
    """Calculate the estimated time remaining."""
    millis_remaining = int(
        (pages_remaining * ESTIMATED_TIME_FOR_PROCESSING_PAGE)
        + (
            pages_remaining
            * ESTIMATED_TIME_FOR_PROCESSING_DATAFRAME_PER_PAGE_OF_RESULTS
        )
    )
    seconds_remaining = (millis_remaining / 1000) % 60
    seconds_remaining = int(seconds_remaining)
    minutes_remaining = (millis_remaining / (1000 * 60)) % 60
    minutes_remaining = int(minutes_remaining)
    return "{}m{:2}s".format(minutes_remaining, seconds_remaining)
```

### Some objects to store the data in

```python {linenos=table,linenostart=66}
    artist_names = []
    album_names = []
    track_names = []
    timestamps = []
    urls = []
```

`urls` is going to be a list of URLs which we will construct and pass to a thread pool to be processed parallely.

### Add request URLs to urls list

```python {linenos=table,linenostart=72}
    for page in range(0, int(total_pages) + 1, 1):
        urls.append(url.format(endpoint, username, key, limit, extended, page))
```

### Starting the thread pool and making all requests

```python {linenos=table,linenostart=74}
    p = pool.Pool.from_urls(urls)
    p.join_all()
```

### Parsing the date from last.fm

Now we have a `p` object containing all the responses from the API, we can do
some processing on it and grab what we want out of it.

```python {linenos=table,linenostart=77}
    for response in p.responses():
        if endpoint in response.json():
            response_json = response.json()[endpoint]["track"]
            for track in response_json:
                if "@attr" not in track:
                    artist_names.append(track["artist"][TEXT])
                    album_names.append(track["album"][TEXT])
                    track_names.append(track["name"])
                    timestamps.append(track["date"]["uts"])
```

`method` and `@attr` are to do with currently scrobbling songs. They return a
different structure of Json so I just skip them.

All we're doing here is looping through the API responses and putting them in the appropriate
list. Note that they will be out of order, so we also take the `UTC` time stamp to eventually
sort our DataFrame by.

### Pandas to create a CSV

And the final step is to create a Pandas dataframe in order to output our data to CSV:

```python {linenos=table,hl_lines=[9],linenostart=88}
    # create and populate a dataframe to contain the data
    df = pd.DataFrame()
    df["artist"] = artist_names
    df["album"] = album_names
    df["track"] = track_names
    df["timestamps"] = timestamps
    # In UTC. Last.fm returns datetimes in the user's locale when they listened
    df["datetime"] = pd.to_datetime(timestamps, unit="s")
    df.sort_values("timestamps", ascending=False, inplace=True)
```

Notice that we use the timestamps to sort the dataframe so the most recent tracks are at the top.

Finally, we write that data to a CSV and save it to disk:

```python {linenos=table,linenostart=1}
scrobbles.to_csv("./data/lastfm_scrobbles.csv", index=False, encoding="utf-8")
print("{:,} total rows".format(len(scrobbles)))
scrobbles.head()
```

You will now have a populated `data/lastfm_scrobbles.csv` in the repo where you cloned the code.

## Wrapping up

Now you have a CSV containing *all* of your last.fm scrobbles from now back to
when you first started scrobbling.

Here's an excerpt of the CSV I get out:

```txt
artist,album,track,timestamps,datetime
Wingnut Dishwashers Union,Burn the Earth! Leave It Behind!,Proudhon in Manhattan,1603055259,2020-10-18 21:07:39
Ramshackle Glory,Live the Dream,Your Heart Is a Muscle the Size of Your Fist - Live,1603055038,2020-10-18 21:03:58
Rent Strike,IX,I: Snowdrop,1603054871,2020-10-18 21:01:11
Rent Strike,Burn It All!,Burn it all!,1603054676,2020-10-18 20:57:56
Rent Strike,Burn It All!,They Live!!,1603054446,2020-10-18 20:54:06
Rent Strike,Burn It All!,Ether Rag,1603054286,2020-10-18 20:51:26
Rent Strike,IX,IX: To the West!!,1603053963,2020-10-18 20:46:03
Rent Strike,IX,VIII: Shadow&Gloom,1603053735,2020-10-18 20:42:15
Rent Strike,IX,VII:,1603053518,2020-10-18 20:38:38
Rent Strike,IX,VI: Don't Let Love Bog You Down,1603053297,2020-10-18 20:34:57
Rent Strike,IX,V: Fair Trade Death March,1603052966,2020-10-18 20:29:26
Rent Strike,IX,"IV: Me, Myself & The Eye",1603052652,2020-10-18 20:24:12
Rent Strike,IX,III: Family Graveyard,1603052352,2020-10-18 20:19:12
Rent Strike,IX,II: The Road Giveth...,1603052111,2020-10-18 20:15:11
Rent Strike,IX,I: Snowdrop,1603051944,2020-10-18 20:12:24
Elton John,Madman Across The Water,Tiny Dancer,1603050610,2020-10-18 19:50:10
Wingnut Dishwashers Union,Burn the Earth! Leave It Behind!,My Idea of Fun!,1603028042,2020-10-18 13:34:02
Wingnut Dishwashers Union,Burn the Earth! Leave It Behind!,Urine Speaks Louder Than Words,1603027921,2020-10-18 13:32:01
```

## Generating a bar chart from your results

Now you have all your data, you can use `plot.py` which is included in the repository to generate a bar chart.

```python {linenos=table,linenostart=1}
import sys

import matplotlib.pyplot as plt
import pandas as pd


def load_and_arrange_data_frame():
    """Get the the artist out of the dataframe and drop other columns.

    Relies on you having run downloader.py first to populate the CSV.
    """
    try:
        dataframe = pd.read_csv("data/lastfm_scrobbles.csv")
    except FileNotFoundError:
        print(
            """
            data/lastfm_scrobbles.csv not found.
            Make sure you run downloader.py before running this script.
            """
        )
        sys.exit(1)

    dataframe = dataframe.drop(["album", "track", "datetime", "timestamps"], axis=1)
    dataframe["scrobbles"] = dataframe.groupby("artist")["artist"].transform("count")
    dataframe = dataframe.drop_duplicates()
    return dataframe.sort_values(by="scrobbles", ascending=False)


def get_plot(dataframe):
    """Arrange the plot.

    Creates a bar chart with Artist on the x axis and number of scrobbles of
    that artist on the y axis.

    Rotates the artist names on the x axis so they fit on the chart.
    """
    plt.xkcd()
    dataframe = dataframe.iloc[0:20]
    dataframe.plot(x="artist", y="scrobbles", kind="bar")
    plt.tick_params(axis="x", pad=6)
    plt.margins(0.2)
    plt.xticks(fontsize=8, horizontalalignment="left")
    plt.tight_layout()
    plt.xticks(rotation=-45)
    plt.ylabel("Scrobbles")
    plt.tick_params(axis="x", which="major", pad=10)
    plt.subplots_adjust(right=0.9, bottom=0.3)
    plt.tight_layout()
    return plt


arranged_dataframe = load_and_arrange_data_frame()
plot = get_plot(arranged_dataframe)

# Save plot to ./chart.png
plt.savefig("chart.png", dpi=500)
print("Saved chart to ./chart.png.")
```

{{< figure src="/img/top_scrobbles.png" caption="Don't judge me" width="800"
height="600" alt="Top scrobbles">}}

## Other ideas

### Finding how many times you've listened to a song

```sh
rg "little wing" data/lastfm_scrobbles.csv | wc -l
    33
```
### Finding how many times you've listened to an artist

```sh
➜ rg "rent strike" data/lastfm_scrobbles.csv| wc -l
      89
```
If you want to see the full Python script, it's here:
<https://github.com/mathieuhendey/lastfm_downloader/blob/master/downloader.py>

[^1]: https://requests.readthedocs.io/en/master/
[^2]: https://pandas.pydata.org/
[^3]: https://matplotlib.org/
[^4]: https://toolbelt.readthedocs.io/en/latest/threading.html
