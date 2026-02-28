import csv
import re
import sys
import json
import subprocess

# This script imports a CSV file, and bulk updates the chart metadata files
#
# Requirements:
# python3 I believe
# and you need to have npm/npx, as we use that to run prettier to keep the same formatting
#
# Usage:
# In our Google Sheets, export as .csv file
#
# Then in here from within this directory, run:
# python3 sheetsToCharts.py path/to/csv/file.csv
#
# use from within this directory, as the paths to the chart metadata files are relative to this directory


# Get the command line argument, if one wasn't already provided
if len(sys.argv) < 2:
  csv_file = input("Please provide the CSV file path: ")
else:
  csv_file = sys.argv[1]

# Open the CSV file
with open(csv_file, 'r') as file:
  reader = csv.reader(file)

  # Which rows for each difficulty are we looking for
  diff_rows = {}

  # Iterate over each row in the CSV file
  for idx, row in enumerate(reader):

    # The first row has headers for the columns, stuff like "Easy - Difficulty", so we want
    # to know which rows corresponde to which difficulty
    if idx == 0:
      pattern = r"\b(?:difficulty)\b"

      diff_cols = []
      diff_words = []

      # Go through each column, and see if it includes the word "difficulty"
      # then append the column index, and the first word of the column (usually what difficulty it is, "easy", "normal", "hard", etc.)
      for colindex, column in enumerate(row):
        txt = re.findall(pattern, column, flags=re.IGNORECASE)
        if txt:
          diff_cols.append(colindex)
          diff_words.append(column.split()[0].lower())

      # We then create a dictionary for use later, where the key is the difficulty, and the value is the column index
      diff_rows = dict(zip(diff_words, diff_cols))
    else:
      # Some song title parsing, to match the filenames we used in for the chart files
      song_title = row[1].lower() # we use lowercase for filenames, SOUTH -> south
      song_title = song_title.replace(" ", "-") # usually we change spaces to dashes, PHILLY NICE -> philly-nice
      song_title = song_title.replace(".", "") # M.I.L.F. -> milf
      song_title = song_title.replace("'", "") # blazin' -> blazin

      # we open the chart metadata json file for writing and reading ("r+")
      with open(f"../../../assets/preload/data/songs/{song_title}/{song_title}-metadata.json", "r+") as chart_metadata_file:

        json_data = json.load(chart_metadata_file) # load the file as a python data structure/dict
        play_data = json_data["playData"] # we want to modify the "playData" section, as that holds the difficulty

        # note to self, python equals(=) operator seems to create a reference for the variable,
        # so modifying play_data will also modify json_data, so we can save json_data easily later

        # if the chart metadata file doesn't already have a "ratings" dict/section, we create one here with 0 for each
        if "ratings" not in play_data:
          play_data["ratings"] = {'easy': 0, 'normal': 0, 'hard': 0}

        ratings = play_data["ratings"]

        # Now we go through our data from the csv file, and the data we kept from the columns there
        # will be put into our new ratings var, if it exists
        for diff, col in diff_rows.items():
          if row[col] == "":
            continue
          if diff in ratings:
            ratings[diff] = round(float(row[col])) # convert the string to a float, and then round it to nearest int

        # Convert the python json_data dict back to a json string
        json_output = json.dumps(json_data)

        # Write the json string back to the file, and truncate the rest of the file
        chart_metadata_file.seek(0)
        chart_metadata_file.write(json_output)
        chart_metadata_file.truncate()
        chart_metadata_file.close()

# Bit hacky, but we simply run `npx prettier` using the same rules we use for FNF here
# essnetially running it via cli and passing in the songs folder and our prettier config file
# This should make the spacing and formatting consistent
command = "npx prettier  ../../../assets/preload/data/songs --write --config ../../../.prettierrc.js"
subprocess.run(command, shell=True)
