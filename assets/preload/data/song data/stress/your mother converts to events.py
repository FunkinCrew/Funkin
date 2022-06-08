# fard
import json
import os
from random import randint # fard 2

# change this for different file name :troll:
file = open(os.getcwd() + "/picospeaker.json")

jsonData = json.load(file)["song"]

ourOwnDataLol = []

for section in jsonData["notes"]:
    for note in section["sectionNotes"]:
        animNum = note[1]

        if animNum != 3:
            animNum += randint(0, 1)
        else:
            animNum -= randint(0, 1)

        eventData = ["Play Character Animation", note[0], "gf", "shoot" + str(animNum + 1)]

        ourOwnDataLol.append(eventData)

print(ourOwnDataLol)

# yeah memory leaks are bad B)))
file.close()