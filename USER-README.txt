How to use:
  Custom Songs:
    Make a new folder in assets/data
    Name it what you want the song name to be but lowercase and replace spaces
    with "-"
    (like Life Will Change > life-will-change)
    Add json files to folder
    Rename each file to the folder name + the difficulty ending, if applicable
    Make a temp folder in assets/music
    Add the music to the folder
    Rename them to the name of the song with hyphens ("-") with the suffix
    (like Life Will Change > Life-Will-Change)
    Drag them out to assets/music
    Go to freeplaySonglist.txt
    Add the song name to it, with the same name as the music files
    (like Life Will Change > Life-Will-Change)
    Launch FNF
    For each difficulty:
    Open the song
    Hit the '7' key
    Go to the song tab
    Click on the text box
    Replace what is in there with the name of the music files
    (like Life Will Change > Life-Will-Change)
    Hit 'Save'
    Save the file and remember to add the difficulty suffix
    After finishing this add the saved file to the folder and overwrite.
  Custom Characters:
    Go to assets/images/custom_chars
    Drag in the mod png and xml (if no xml grab the base game one)
    Rename them to the name of the character (should be lowercase)
    If there are custom icons:
      Add the iconGrid.png
      Rename to (character name)_icons.png
    Open custom_chars.json
    Add a new property:
      "(character name)": {
        "like": "(character this is based on)",
        "icons": [(alive icon number),(dead icon number)]
      }
    Remember your commas!
    Characters also now support portraits.
    If your character has a portrait drag it in and rename it to your character
    name + '-portrait'
    They also support custom death sprites.
    If your character is based on pixel bf:
    drag in the death png + xml
    rename to '(character name)-dead'
    If it is based on bf: Great! Everything is already done for custom death!
    To apply these characters:
    Open a song
    Hit the '7' key
    go to the song tab
    Click on one of the top two dropdowns
    Select your custom character
    Hit save and save the json. Remember difficulty prefixes!
    Custom GF:
      Follow above instructions but instead of choosing one of the top two
      dropdowns choose the one that says gf.
      Choose custom gf
      Hit save and save the json. Remember difficulty prefixes!
  Custom Stages:
    Goto assets/images/custom_stages
    Make a new folder with the name of your stage
    Drag in any custom stage assets
    Add a new property to custom_stages.json:
      "(stage name)": "(stage it is like)"
    Don't forget your commas!
    To apply these stages:
    Open a song
    Hit the '7' key
    go to the song tab
    Click on the drop down that says something like 'stage'.
    Select your custom stage.
    Hit save and save the json. Remember difficulty prefixes!
  Custom Weeks:
    If your mod has a custom week icon:
      Add the xml and png to the assets/images/campaign-ui-week folder
      (if no xml then grab one from one of the other weeks)
      rename them to what the week position is (week6, week7, week8)
    Else:
      Copy one of the weeks png + xml and rename them to the week position
      (week7,week8,week9)
    Open assets/data/storySonglist.json
    Add a new week:
      ["(animation name of the week, look at default weeks)", "(trackname)", "(trackname)", ...]
    Add a new character Array e.g.:
      ["parents-christmas", "bf", "gf"]
    Launch the game, open story menu and see your week!
    Custom UI Characters
      Add the mod png and xml to assets/images/campaign-ui-char
      (if no xml just copy another one)
      Rename files to "(character name)"
      Open custom characters json
      Add new property:
      "(character name)": "(character it goes over)"
      Don't forget your commas!
      To use these just replace the character in the character array with the
      name of your character
  Custom Cutscenes:
    You can now make your own cutscenes!
    To add them: Go to assets/images/custom_ui/dialog_boxes
    drag in the dialog box png + xml
    rename them to what you want the cutscene to be named
    If there is a senpai crazy png + xml, drag those in and rename them
    to the cutscene name +  '-crazy'
    Go to assets/data
    Open up "cutscenes.txt"
    add your cutscene name on a newline!
    Go to the song folder,
    Add a "dialog.txt" file
    Do this format
    "
    :dad: Senpai speaking
    :bf: Bf speaking
    "
    Also add a Lunchbox.ogg if you want dialog sound
    To apply these cutscenes:
    Open a song
    Hit the '7' key
    go to the song tab
    Click on the drop down that says something like 'senpai'.
    Select your custom stage.
    Hit save and save the json. Remember difficulty prefixes!
  Custom UI:
    You can now add custom ui!
    Go to assets/images/custom_ui/ui_packs
    make a new folder with the name of your ui
    Add the following files:
    The arrow files
    The rating files (good, bad, shit, sick)
    The number files
    The intro files (ready, set, go)
    The Ogg files for the intro (intro1, intro2, intro3, introGo)
    (Remember, all of these files are required or the game will crash!)
    Go to assets/data
    Open uitypes.txt
    Add your ui type name on a new line!
    To apply these uis:
    Open a song
    Hit the '7' key
    go to the song tab
    Click on the drop down that says something like 'normal'.
    Select your custom stage.
    Hit save and save the json. Remember difficulty prefixes!
  Custom Difficulties:
    To add custom difficulties:
    go to assets/images/custom_difficulties
    add your difficulty png + xml
    add a new entry to difficulties.json inside of the array
    {
      "offset": (how far it should be offset from the arrow(?)),
      "anim": "(the animation name)",
      "name": "(the name used in freeplay mode)"
    }
    if you want to change the default difficulty change
    default to the position in the list - 1
    For songs you have to make a new json using the chart editor and rename
    the file with "-(difficulty name)" at the end.
