# Dota 2 Live Match Data ETL
This script is designed to perform Extract, Transform, and Load (ETL) operations on live Dota 2 match data. It retrieves information from both the Steam and Stratz APIs, processes the data, and generates a dataset for analysis and predictions.

## Components
Data Extraction:

Utilizes the Steam API (http://api.steampowered.com/IDOTA2Match_570/GetLiveLeagueGames/V001/) for live match details in JSON format.
Queries the Stratz API (https://api.stratz.com/api/v1/) to gather additional information on live matches.
Data Transformation:

- Parses extracted data, emphasizing game and team details.  
- Computes various scores and statistics, including synergy scores, matchup scores, and peer scores for players and teams.  
- Handles discrepancies and incomplete data gracefully.  


## Data Loading:

Organizes processed data into a structured dataset suitable for analysis and predictions.  
Includes essential match information, team details, and computed scores.  
### Data Quality and Filtering:

Ensures the dataset contains only complete and valid game information.  
Filters out incomplete or irrelevant data.  


### Dataset Output:

Outputs the finalized dataset in CSV format for further use.  
Differentiates between data sources, marking whether the information comes from Steam or Stratz.  


# Usage
Initialization:  
Create an instance of the Live_watcher class, an extension of the Api_handler class.  

## Data Extraction:  

Retrieve live match data from both Steam and Stratz APIs.  
Process and combine data from these sources.  

## Data Transformation:

Calculate various scores for player synergy, hero matchups, and player peers.  
Handle discrepancies and exceptions during the transformation process.  


## Data Loading:

Prepare processed data for analysis and prediction.  
Output the dataset to a CSV file (./data/live_games.csv).  

## Execution:

Invoke the get_live() function to execute the entire ETL process and obtain the final dataset.  
Data Details  


## The dataset includes:

### Match Information:

Match ID  
Winner  
Version  
Game Time  
Average MMR  
Game Mode  
League ID  
Last Update Time  

### Team Details:

Team ID  
Team Name  
Players  
Account ID  
Hero ID  
Is Radiant (Boolean)  
Name  
Is Pro (Boolean)  


### Calculated Scores:

Synergy Scores:  
A measure of how well players on a team work together, computed based on players' account IDs and hero IDs.    
Matchup Scores:  
Scores indicating the compatibility between heroes in a team, calculated from players' hero IDs.    
Peer Scores:  
Scores reflecting players' performance relative to their peers, determined from players' account IDs.    

## Note
This script focuses on extracting, transforming, and loading live Dota 2 match data for subsequent analysis. The API-related functionalities are not discussed in this summary.
