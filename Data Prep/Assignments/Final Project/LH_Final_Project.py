#!/usr/bin/env python
# coding: utf-8

# In[1]:


#Importing the libraries
from pprint import pprint
import requests
import http.client
import json
import pandas as pd
from datetime import datetime as dt
import time
from decouple import Config, Csv

# Load environment variables directly from the notebook
get_ipython().run_line_magic('load_ext', 'dotenv')
get_ipython().run_line_magic('dotenv', '-v')

# Access environment variables using %env
jambase_api = get_ipython().run_line_magic('env', 'jambase_api')
last_fm_api = get_ipython().run_line_magic('env', 'last_fm_api')


# In[2]:


# Creating the API call
conn = http.client.HTTPSConnection("www.jambase.com")

headers = {'Accept': "application/json"}

# Creating a list of dictionaries to store parsed concerts
events_data = []


# Getting 20 pages of info
for page in range(20):
    conn.request("GET", f"/jb-api/v1/events?page={page}&perPage=50&geoStateIso=US-TX&apikey={jambase_api}", headers=headers)

    res = conn.getresponse()
    data = res.read()

    decoded_data = data.decode("utf-8")

    # Use the json module to load the JSON data
    json_data = json.loads(decoded_data)

    for event in range(len(json_data.get('events', []))):
        # Skipping non-concert events
        if json_data['events'][event].get('@type') != 'Concert':
            continue

        # Check if 'offers' is not an empty list before accessing its first element.
        offers = json_data['events'][event].get('offers', [])
        ticket_url = offers[0]['url'] if offers else 'No Ticket Link'

        #Creating a dictionary of event data
        event_data = {
            'headliner_name': json_data['events'][event]['performer'][0].get('name', 'Unknown Headliner'),
            'event_date': json_data['events'][event].get('endDate', 'No End Date'),
            'event_venue': json_data['events'][event].get('location', {}).get('name', 'No Venue Name'),
            'event_status': json_data['events'][event].get('eventStatus', 'No Event Status'),
            'venue_address': (
                json_data['events'][event].get('location', {}).get('address', {}).get('streetAddress', '') +
                ', ' +
                json_data['events'][event].get('location', {}).get('address', {}).get('addressLocality', '') +
                ' ' +
                json_data['events'][event].get('location', {}).get('address', {}).get('addressRegion', {}).get('name', '') +
                ' ' +
                json_data['events'][event].get('location', {}).get('address', {}).get('postalCode', '')
            ),
            'artist_genre': json_data['events'][event]['performer'][0].get('genre', 'No Genre'),
            'ticket_link': ticket_url
        }

        events_data.append(event_data)

# Convert the list of dictionaries to a DataFrame
all_concerts = pd.DataFrame(events_data)
all_concerts.head()


# In[3]:


# due to the volume of artists, I defined a function to handle Last.fm API requests

def get_lastfm_artist_info(artist):

    headliner_name, listeners, playcounts = artist, 'Artist data not available', 'Artist data not available'
    
    try:
        # Last.fm API endpoint for artist.getinfo
        url = f"http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&artist={artist}&api_key={last_fm_api}&format=json"

        # Making the GET request
        response = requests.get(url)

        # Check for HTTP errors
        response.raise_for_status()

        # Decode JSON content
        artist_info = response.json()

        # Only take instances where there is no errors
        if 'error' not in artist_info:
            artist_info = artist_info.get('artist')
            if artist_info:
                headliner_name = artist_info.get('name', artist)
                listeners = artist_info['stats'].get('listeners', 'Listener data not available')
                playcounts = artist_info['stats'].get('playcount', 'Playcount data not available')

    # adding some exemption flags for debugging
    except requests.exceptions.RequestException as e:
        print(f"Request Exception: {e}")
    except json.JSONDecodeError as e:
        print(f"JSON Decode Error: {e}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

    return headliner_name, listeners, playcounts

# Pulling artist info from Last.fm
headliners = all_concerts['headliner_name'].drop_duplicates().tolist()
all_artist_info = []

for artist in headliners:
    artist_name, listeners, playcounts = get_lastfm_artist_info(artist)
    all_artist_info.append({
        'headliner_name': artist_name,
        'listeners': listeners,
        'playcounts': playcounts
    })
    # Adding a delay between requests to avoid overwhelming the Last.fm API
    time.sleep(1)

# Convert the list of dictionaries to a DataFrame
artist_info_df = pd.DataFrame(all_artist_info)
artist_info_df.head()


# In[6]:


# Finding the top played album


# Creating a dataset with listeners and playcounts
artist_plays = pd.DataFrame({'headliner_name': headliners, 'n_listeners': listeners, 'artist_playcount': playcounts})
# Convert 'artist_playcount' column to integers
artist_plays['artist_playcount'] = pd.to_numeric(artist_plays['artist_playcount'], errors='coerce')
# Sort the DataFrame by 'artist_playcount' in descending order
artist_plays = artist_plays.sort_values('artist_playcount', ascending=False)
# Display the DataFrame
artist_plays=artist_plays.drop_duplicates()
artist_plays.head()




# In[7]:


# Joining back to the main dataset.
all_concerts=pd.merge(all_concerts, artist_plays, 'left')
all_concerts.head()


# In[9]:


artist_names=[]
album_names = []
album_names=[]
playcounts=[]

for artist in headliners:
    artist_name = artist
    # Last.fm API endpoint for getting the top albums for artists
    url = f"http://ws.audioscrobbler.com/2.0/?method=artist.gettopalbums&artist={artist_name}&api_key={last_fm_api}&format=json"

    # Making the GET request
    response = requests.get(url).json()
    # Add a delay between requests to avoid overwhelming the Last.fm API
    time.sleep(1)
    if 'topalbums' in response and 'album' in response['topalbums']:
        for i in range(len(response['topalbums']['album'])):
            artist_names.append(artist_name)
            album_names.append(response['topalbums']['album'][i]['name'])
            playcounts.append(response['topalbums']['album'][i]['playcount'])
    else:
        pass


# In[10]:


# Create an empty DataFrame to store the top albums
top_albums = pd.DataFrame()
album_plays=pd.DataFrame({'headliner_name':artist_names,'top_album':album_names, 'album_playcount':playcounts})
album_plays['album_playcount']=album_plays['album_playcount'].astype(int)
album_plays=album_plays.sort_values('album_playcount', ascending=False)


album_plays.head()
# Iterate over unique artists
for artist in album_plays['headliner_name'].unique():
    # Extract data for the current artist
    artist_sub = album_plays[album_plays['headliner_name'] == artist]
    
    # Sort by playcount in descending order
    artist_sub = artist_sub.sort_values('album_playcount', ascending=False)
    
    # Take the top album for the current artist
    top_album = artist_sub.head(1)
    
    # Concatenate to the top_albums DataFrame
    top_albums = pd.concat([top_albums, top_album], ignore_index=True)

# Display the overall top albums
top_albums.head(10)


# In[11]:


# Joining back to the main dataset
all_concerts=pd.merge(all_concerts, top_albums, 'left')
all_concerts.head()


# In[12]:


#Finding the overall top played artist coming to town
all_concerts.sort_values('artist_playcount', ascending=False, inplace=True)
all_concerts[['headliner_name','event_venue','top_album','artist_genre']].head(1)


# In[13]:


# Writing the final dataset to a .csv
all_concerts.to_csv('all_concerts.csv', index=False)

