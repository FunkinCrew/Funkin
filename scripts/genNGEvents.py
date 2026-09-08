import requests
import sys

# Unique identifier for the analytics or tracking project
PROJECT_ID = 5582053

# DOM manipulation template string to trigger new event insertion via jQuery
TEMPLATE = 'jQuery("#new-event-name").val("{event}"); jQuery("#save-new-event").click();'

# Base list of event patterns to be formatted with variables
EVENT_TEMPLATES = [
    "start-game",
    "watch-cartoon",
    "open-credits",

    "start-song_{songId}-{variation}",
    "blueballs_{songId}-{variation}",
    "complete-song_{songId}-{variation}",
    "start-level_{levelId}",
    "complete-level_{levelId}",
    "earn-rank_{rankName}",
]

# Mapping of all available song IDs and their respective gameplay variations
SONG_IDS = [
    { "songId": "tutorial", "variation": "default" },
    { "songId": "tutorial", "variation": "erect" },
    { "songId": "tutorial", "variation": "pico" },

    { "songId": "bopeebo", "variation": "default" },
    { "songId": "bopeebo", "variation": "erect" },
    { "songId": "bopeebo", "variation": "pico" },

    { "songId": "fresh", "variation": "default" },
    { "songId": "fresh", "variation": "erect" },
    { "songId": "fresh", "variation": "pico" },

    { "songId": "dadbattle", "variation": "default" },
    { "songId": "dadbattle", "variation": "erect" },
    { "songId": "dadbattle", "variation": "pico" },

    { "songId": "spookeez", "variation": "default" },
    { "songId": "spookeez", "variation": "erect" },
    { "songId": "spookeez", "variation": "pico" },

    { "songId": "south", "variation": "default" },
    { "songId": "south", "variation": "erect" },
    { "songId": "south", "variation": "pico" },

    { "songId": "monster", "variation": "default" },
    { "songId": "monster", "variation": "erect" },
    { "songId": "monster", "variation": "pico" },

    { "songId": "pico", "variation": "default" },
    { "songId": "pico", "variation": "erect" },
    { "songId": "pico", "variation": "pico" },

    { "songId": "philly-nice", "variation": "default" },
    { "songId": "philly-nice", "variation": "erect" },
    { "songId": "philly-nice", "variation": "pico" },

    { "songId": "blammed", "variation": "default" },
    { "songId": "blammed", "variation": "erect" },
    { "songId": "blammed", "variation": "pico" },

    { "songId": "satin-panties", "variation": "default" },
    { "songId": "satin-panties", "variation": "erect" },
    { "songId": "satin-panties", "variation": "pico" },

    { "songId": "high", "variation": "default" },
    { "songId": "high", "variation": "erect" },
    { "songId": "high", "variation": "pico" },

    { "songId": "milf", "variation": "default" },
    { "songId": "milf", "variation": "erect" },
    { "songId": "milf", "variation": "pico" },

    { "songId": "cocoa", "variation": "default" },
    { "songId": "cocoa", "variation": "erect" },
    { "songId": "cocoa", "variation": "pico" },

    { "songId": "eggnog", "variation": "default" },
    { "songId": "eggnog", "variation": "erect" },
    { "songId": "eggnog", "variation": "pico" },

    { "songId": "winter-horrorland", "variation": "default" },
    { "songId": "winter-horrorland", "variation": "erect" },
    { "songId": "winter-horrorland", "variation": "pico" },

    { "songId": "senpai", "variation": "default" },
    { "songId": "senpai", "variation": "erect" },
    { "songId": "senpai", "variation": "pico" },

    { "songId": "roses", "variation": "default" },
    { "songId": "roses", "variation": "erect" },
    { "songId": "roses", "variation": "pico" },

    { "songId": "thorns", "variation": "default" },
    { "songId": "thorns", "variation": "erect" },
    { "songId": "thorns", "variation": "pico" },

    { "songId": "ugh", "variation": "default" },
    { "songId": "ugh", "variation": "erect" },
    { "songId": "ugh", "variation": "pico" },

    { "songId": "guns", "variation": "default" },
    { "songId": "guns", "variation": "erect" },
    { "songId": "guns", "variation": "pico" },

    { "songId": "stress", "variation": "default" },
    { "songId": "stress", "variation": "erect" },
    { "songId": "stress", "variation": "pico" },

    { "songId": "darnell", "variation": "default" },
    { "songId": "darnell", "variation": "erect" },
    { "songId": "darnell", "variation": "bf" },

    { "songId": "lit-up", "variation": "default" },
    { "songId": "lit-up", "variation": "erect" },
    { "songId": "lit-up", "variation": "bf" },

    { "songId": "2hot", "variation": "default" },
    { "songId": "2hot", "variation": "erect" },
    { "songId": "2hot", "variation": "bf" },

    { "songId": "blazin", "variation": "default" },
    { "songId": "blazin", "variation": "erect" },
    { "songId": "blazin", "variation": "bf" },
]

# List of game levels/weeks
LEVEL_IDS = [
    "tutorial",
    "week1",
    "week2",
    "week3",
    "week4",
    "week5",
    "week6",
    "week7",
    "weekend1",
    "week8",
]

# Performance ranks obtainable in the game
RANKS = [
    "PERFECT_GOLD",
    "PERFECT",
    "EXCELLENT",
    "GREAT",
    "GOOD",
    "SHIT",
]


# Populates song template strings with corresponding song IDs and variations
def formatEventSong(event):
    result = []
    for song in SONG_IDS:
        result.append(event.format(
            songId = song["songId"],
            variation = song["variation"]
        ))
    return result

# Populates level template strings with level IDs
def formatEventLevel(event):
    result = []
    for level in LEVEL_IDS:
        result.append(event.format(
            levelId = level
        ))
    return result

# Populates rank template strings with rank names
def formatEventRank(event):
    result = []
    for rank in RANKS:
        result.append(event.format(
            rankName = rank
        ))
    return result

# Routes the event template to its specific formatter based on placeholder tags
def formatEvent(event):
    if "{songId}" in event or "{variation}" in event:
        return formatEventSong(event)

    if "{levelId}" in event:
        return formatEventLevel(event)

    if "{rankName}" in event:
        return formatEventRank(event)

    # Return as-is if no placeholders are found
    return [event]

# Prints the final formatted jQuery script command to stdout
def createEvent(event):
    print(TEMPLATE.format(event=event))

# Main Execution Flow
def main():
    event_list = []

    # Format all defined template patterns
    for event in EVENT_TEMPLATES:
        event_list.extend(formatEvent(event))

    # Deduplicate the list using set conversion and sort alphabetically
    event_list = list(set(event_list))
    event_list.sort()

    # Generate output script for each unique event name
    for event in event_list:
        createEvent(event)

# Entry point of the script
if __name__ == "__main__":
    main()


# ==============================================================================
# BROWSER CONSOLE SNIPPET (JavaScript / Reference Code)
# ==============================================================================

# Helper function to pause execution for a given time in milliseconds
# function sleep(ms) {
#   console.log("sleeping for " + ms + "ms");
#   return new Promise(resolve => setTimeout(resolve, ms));
# }

# Example asynchronous routine to simulate user interactions on the page
# async function example() {
#   jQuery("#new-event-name").val("blueballs_blazin-erect"); jQuery("#save-new-event").click();
#   await sleep(1000);
#   jQuery("#new-event-name").val("blueballs_blazin-erect"); jQuery("#save-new-event").click();
#   await sleep(1000);
# }

# Run the async example routine
# example();
