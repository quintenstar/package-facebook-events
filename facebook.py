#!/usr/bin/python2.7
import os
import sys
import time
from datetime import datetime
import hashlib

import traceback
from operator import itemgetter

try:
    from StringIO import StringIO  # for Python 2
except ImportError:
    from io import StringIO  # for Python 3

import requests

try:
    from hosted import node
except ImportError:
    print("Import error on hosted node.write_json")

    class node(object):
        @staticmethod
        def write_json(file, text):
            print(json.dumps(text, indent=4))


from PIL import Image


def cache_image(url, ext="jpg"):
    cache_name = "cache-image-%s.%s" % (hashlib.md5(url).hexdigest(), ext)
    print >>sys.stderr, "caching %s" % url
    if not os.path.exists(cache_name):
        try:
            r = requests.get(url, timeout=20)
            fobj = StringIO(r.content)
            im = Image.open(fobj)  # test if it opens
            del fobj
            im.save(cache_name)
        except:
            traceback.print_exc()
            return
    return cache_name


def cache_images(urls):
    cached_images = []
    for url in urls:
        cached = cache_image(url)
        if cached:
            cached_images.append(cached)
    return cached_images


def save_events(events):
    events = [convert(event) for event in events]
    events.sort(key=itemgetter("start_time"), reverse=True)
    node.write_json("events.json", events)


def cleanup(max_age=12 * 3600):
    now = time.time()
    for filename in os.listdir("."):
        if not filename.startswith("cache-"):
            continue
        age = now - os.path.getctime(filename)
        if age > max_age:
            try:
                os.unlink(filename)
            except:
                traceback.print_exc()


def date_to_time(date):
    """FB date format to time"""
    d = datetime.strptime(date[:-5], "%Y-%m-%dT%H:%M:%S")
    return int(time.mktime(d.timetuple()))


def convert(event):
    converted = {}
    for field in fields:
        try:
            if "time" in field:
                converted[field] = date_to_time(event[field])
            elif field == "cover":
                cached_image = cache_image(event["cover"]["source"], ext="jpg")
                if cached_image:
                    converted[field] = cached_image

            else:
                converted[field] = event[field]
        except KeyError:  # field doesn't exist (end_time)
            converted[field] = 0

    return converted


fields = ["id", "name", "owner", "start_time", "end_time", "cover", "place"]


def get_events(access_token, page_id, events_max=5):
    print >>sys.stderr, "getting events from page_id: " + page_id

    query = (
        "https://graph.facebook.com/"
        + page_id
        + "/events?fields="
        + ",".join(fields)
        + "&limit="
        + str(events_max)
        + "&access_token="
        + access_token
        + "&time_filter=upcoming"
        + "&event_state_filter=['published']"
    )

    r = requests.get(query)
    events = r.json()["data"]

    events = [convert(event) for event in reversed(events)]
    return events


if __name__ == "__main__":
    import json

    from dotenv import dotenv_values
    config = dotenv_values(".env")

    events = get_events(config["ACCESS_TOKEN"], config["PAGE_ID"])

    with open("events.json.test", "w") as fp:
        json.dump(events, fp, indent=2)
