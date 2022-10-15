"""
* Programmer Name - Benjamin Moeller
* Description - Holds signals that need to be used globally (aka emitted in one file, connected in another)
* Date Created - 10/12/2022
* Date Revisions:
	10/14/2022 - Added the openMenu signal
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
