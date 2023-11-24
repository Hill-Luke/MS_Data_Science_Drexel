# Concert Data Analysis

This Python script retrieves concert data from the Jambase API in the state of Texas, gathers information about the headlining artists from the Last.fm API, and performs some light analysis on the data.

# Requirements

Make sure to install the required libraries before running the script:

```bash
pip install requests pandas python-decouple
```
# Usage

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
# Description

The script does the following:

    Retrieves concert data from Jambase API for events in Texas.
    Collects information about headlining artists from Last.fm API.
    Analyzes top played albums and artists.
    Outputs the final dataset to a CSV file (all_concerts.csv).

Dependencies

- pprint
- requests
- http.client
- json
- pandas
- datetime
- time
- decouple

Output

The final dataset is saved as all_concerts.csv and includes information about concerts, headlining artists, top albums, and more.

Feel free to explore the dataset for insights into upcoming concerts and popular artists in the Texas area!
