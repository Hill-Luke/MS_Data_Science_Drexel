# Concert Data Analysis

This Python script retrieves concert data from the Jambase API in the state of Texas, gathers information about the headlining artists from the Last.fm API, and performs some light analysis on the data.

# Description

__Scipt Summary:__

    This program pulls information about upcoming live music events from Jambase at the state-level. For demo purposes, I have set the geography to my home state of Texas--however future users can change the state geography to their liking. I have configured the program with a masked API key for security purposes, so future users will need to create a .env file in the same folder as the program to run appropriately (see usage instructions for more details.)

    The Jambase API pulls information about the headlining artist, genre, venue name, venue address, and provides a link to purchase tickets.

    The script then pings an API from Last.fm, a website dedicated to music discovery, recommendation, and social networking. The API pulls in additional data on the artists playing in the geography, including how many streams an artist has and what their top album is. 

    Once the APIs pull the data in .json format, the program then parses the information appropriately and joins the data together by artist name.
    
    One of the more challenging aspects of the script was dealing with relatively obscure or local artists that did not have stream information in last.fm. Anytime one of these artists occured, the API would corrupt the output. Thus, the script was developed to account for exceptions in the API pull. 
    
    Another unexpected challenge was that the API only pulls upcoming concerts and cannot look back historically. This presents a challenge for anyone hoping to do a retrospective analysis or looking to do a longitudinal analysis. To support these types of analyses, one could schedule this script to run once a day and collect this information over an extended period of time.

__Future applications of this data:__
- App development for concert discovery
- Finding the most popular artist coming to a state.
- Mapping the genre of artists visiting your state. 
- Finding the most popular music venues in your area.


# Technical Requirements
__Library Dependencies:__
This code requires the following packages:
- pprint
- requests
- http.client
- json
- pandas
- datetime
- time
- decouple

Make sure to install the required libraries before running the script:

```bash
pip install requests pandas python-decouple
```

__Usage:__

Set up your environment variables by creating a .env file with the following:

1. Set up your environment by creating a `.env` file with the following:
```
	jambase_api=your_jambase_api_key
	last_fm_api=your_last_fm_api_key
```
2. Run the script:
```bash
python LH_Final_Project.py
```
__Output:__

The final dataset is saved as all_concerts.csv and includes information about concerts, headlining artists, top albums, and more.

Feel free to explore the dataset for insights into upcoming concerts and popular artists in the Texas area!
