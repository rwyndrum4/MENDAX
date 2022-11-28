"""
* Programmer Name - Benjamin Moeller & Freeman Spray
* Description - Holds signals that need to be used globally (aka emitted in one file, connected in another)
* Date Created - 10/12/2022
* Date Revisions:
	10/14/2022 - Added the openMenu signal
	10/16/2022 - Added the inputText signal
	10/28/2022 - Added server control signals
	11/28/2022 - Added player death signal
"""

extends Node

"""
* Purpose - Send a signal when a textbox is displayed and goes away
* Used in - textBox.gd and playerScript.gd
* Parameter - value -> boolean (true if currently showing textbox, false if textbox is gone)
"""
# warning-ignore:unused_signal
signal textbox_shift(value)

"""
* Purpose - Send a signal when the options menu is opened up
* Used in - settingsMenu.gd and playerScript.gd
* Parameter - value -> boolean (true if currently showing menu, false if menu is gone)
"""
# warning-ignore:unused_signal
signal openMenu(value)

"""
* Purpose - Send a signal when using chatbox in game scene
* Used in - chatBox.gd, startArea.gd, and entryScene.gd
* Parameter - value -> boolean (true if in chat)
"""
# warning-ignore:unused_signal
signal openChatbox(value)

"""
* Purpose - Send a signal when a message is submitted to the chatbox
* Used in - riddleGame.gd
* Parameter - inText -> string (text of a message)
"""
# warning-ignore:unused_signal
signal inputText(inText)

"""
* Purpose - Send a signal when a message received, to send to riddler minigame
* Used in - riddleGame.gd, globalScope.gd
* Parameter - answer -> string (text of a message)
"""
# warning-ignore:unused_signal
signal answer_received(answer)

"""
* Purpose - Send a signal when a player's hit points are reduced to 0
* Used in - playerScript.gd
* Parameter - playerID -> denotes which player has died (for use in multiplayer setting)
"""
# warning-ignore:unused_signal
signal playerDeath(playerID)
