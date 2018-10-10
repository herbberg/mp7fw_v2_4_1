import logging
import time
import sys

import mp7



def _makeSimpleDemux():
	# 1 mode, 1 capture
	# No delay
	menu = mp7.ReadoutMenu(4,2,4)

	menu.bank(1).wordsPerBx = 6
	menu.bank(2).wordsPerBx = 6

	# Triggers on every event
	mode = menu.mode(0)

	mode.eventSize = 0
	mode.eventToTrigger = 1
	mode.eventType = 0xc0
	mode.tokenDelay = 70

	# Even, bank id 1, +0bx
	c = mode[0]
	c.enable = True
	c.id = 0x1
	c.bankId = 0x2
	c.length = 1
	c.delay = 0
	c.readoutLength = 6

	return menu


def _makeSimpleDemux5BX():
	# 1 mode, 1 capture
	# No delay
	menu = mp7.ReadoutMenu(4,2,4)

	menu.bank(1).wordsPerBx = 6
	menu.bank(2).wordsPerBx = 6

	# Triggers on every event
	mode = menu.mode(0)

	mode.eventSize = 0
	mode.eventToTrigger = 1
	mode.eventType = 0xc0
	mode.tokenDelay = 70

	# Even, bank id 1, +0bx
	c = mode[0]
	c.enable = True
	c.id = 0x1
	c.bankId = 0x2
	c.length = 5
	c.delay = 0
	c.readoutLength = 30

	return menu

def _makeValidationDemux5BX():
	# 1 mode, 1 capture
	# No delay
	menu = mp7.ReadoutMenu(4,2,4)

	menu.bank(1).wordsPerBx = 6
	menu.bank(2).wordsPerBx = 6

	# Triggersevery 107 events
	mode = menu.mode(0)

	mode.eventSize = 0
	mode.eventToTrigger = 107
	mode.eventType = 0xc0
	mode.tokenDelay = 70

	# Outputs, bankId 2, 5 Bxs
	c = mode[0]
	c.enable = True
	c.id = 0x1
	c.bankId = 0x2
	c.length = 5
	c.delay = 0
	c.readoutLength = 30

	# Inputs, bankId 2, 1 Bx
	c = mode[1]
	c.enable = True
	c.id = 0x2
	c.bankId = 0x1
	c.length = 2
	c.delay = 0
	c.readoutLength = 8


	# Triggers on every event
	mode = menu.mode(1)

	mode.eventSize = 0
	mode.eventToTrigger = 1
	mode.eventType = 0xde
	mode.tokenDelay = 70

	# Outputs, bankId 2, 5 Bxs
	c = mode[0]
	c.enable = True
	c.id = 0x2
	c.bankId = 0x2
	c.length = 5
	c.delay = 0
	c.readoutLength = 30

	return menu

def _makeSimpleMPs():
	# 1 mode, 1 capture
	# No delay
	menu = mp7.ReadoutMenu(4,2,4)

	menu.bank(1).wordsPerBx = 6
	menu.bank(2).wordsPerBx = 6

	# Triggers on every event
	mode = menu.mode(0)

	mode.eventSize = 0
	mode.eventToTrigger = 1
	mode.eventType = 0xde
	mode.tokenDelay = 70

	# Outputs, bank id 0x2, 1 bx 
	c = mode[0]
	c.enable = True
	c.id = 0x1
	c.bankId = 0x2
	c.length = 2
	c.delay = 0
	c.readoutLength = 8

	return menu

def _makeValidationMPs():
	# 1 mode, 1 capture
	# No delay
	menu = mp7.ReadoutMenu(4,2,4)

	menu.bank(1).wordsPerBx = 6
	menu.bank(2).wordsPerBx = 6

	# Triggers every 107 event
	mode = menu.mode(0)

	mode.eventSize = 0
	mode.eventToTrigger = 107
	mode.eventType = 0xc0
	mode.tokenDelay = 70

	# Outputs, bank id 0x2, 1 bx 
	c = mode[0]
	c.enable = True
	c.id = 0x1
	c.bankId = 0x2
	c.length = 2
	c.delay = 0
	c.readoutLength = 8

	# Inputs, bank id 0x2, 1 bx 
	c = mode[1]
	c.enable = True
	c.id = 0x2
	c.bankId = 0x1
	c.length = 7
	c.delay = 0
	c.readoutLength = 40

	# Triggers on every event
	mode = menu.mode(1)

	mode.eventSize = 0
	mode.eventToTrigger = 1
	mode.eventType = 0xde
	mode.tokenDelay = 70

	# Even, bank id 1, +0bx
	c = mode[0]
	c.enable = True
	c.id = 0x1
	c.bankId = 0x2
	c.length = 2
	c.delay = 0
	c.readoutLength = 8

	return menu


def _makeMpMenu():

	baseMode = mp7.ReadoutMenu.Mode(4)

	# Common parameters
	# -----------------

	# Inputs, bank id 1
	c = baseMode[0]
	c.enable = True
	c.bankId = 1
	c.id = 0

	# Outputs, bank id 2
	c = baseMode[1]
	c.enable = True
	c.bankId = 2
	c.id = 0

	s2Menu = mp7.ReadoutMenu(4,2,4) # NBanks, NModes, NCaptures

	# Inputs, 6 w per bx
	s2Menu.bank(1).wordsPerBx = 6
	# Outputs, 6 w per bx
	s2Menu.bank(2).wordsPerBx = 6

	s2Menu.setMode(0,baseMode)
	s2Menu.setMode(1,baseMode)

	# First trigger mode, Validation events
	# -------------------------------------

	m = s2Menu.mode(0)
	m.eventSize = 0
	m.eventToTrigger = 107
	m.eventType = 0x1
	m.tokenDelay = 35

	# Inputs, bank id 1, +0bx
	c = s2Menu.capture(0,0) #Mode, #Capture
	c.delay = 0
	c.length = 5
	c.readoutLength = 30

	c = s2Menu.capture(0,1)
	c.delay = 0
	c.length = 5
	c.readoutLength = 30

	# Outputs, bank id 2, +0bx
	c = s2Menu.capture(0,1)
	c.delay = 0
	c.length = 5
	c.readoutLength = 30

	c = s2Menu.capture(1,0)
	c.delay = 0
	c.length = 5
	c.readoutLength = 30


	# Second trigger mode, standard events
	# ------------------------------------

	m = s2Menu.mode(1)
	m.eventSize = 0
	m.eventToTrigger = 1
	m.eventType = 0x0
	m.tokenDelay = 70

	# Inputs, bank id 1, +0bx
	c = s2Menu.capture(1,0)
	c.delay = 0
	c.length = 5
	c.readoutLength = 30

	# Outputs, bank id 2, +0bx
	c = s2Menu.capture(1,1)
	c.delay = 0
	c.length = 5
	c.readoutLength = 30

	return s2Menu

def _makeDemuxMenu():

	baseMode = mp7.ReadoutMenu.Mode(4)

	# Common parameters
	# -----------------

	# Outputs, bank id 2
	c = baseMode[0]
	c.enable = True
	#c.bankId = 2
	c.id = 0

	s2Menu = mp7.ReadoutMenu(4,2,4) #NBanks, NModes, NCaptures

	# Inputs, 6 w per bx
	s2Menu.bank(1).wordsPerBx = 6
	# Outputs, 6 w per bx
	s2Menu.bank(2).wordsPerBx = 6

	s2Menu.setMode(0,baseMode)
	s2Menu.setMode(1,baseMode)

	# First trigger mode, Validation events
	# -------------------------------------

	m = s2Menu.mode(0)
	m.eventSize = 0
	m.eventToTrigger = 107
	m.eventType = 0x1
	m.tokenDelay = 30

	# Outputs, bank id 1, +0bx
	c = s2Menu.capture(0,0)
	c.delay = 0
	c.length = 5
	c.readoutLength = 30

	c = s2Menu.capture(0,1)
	c.delay = 0
	c.length = 5
	c.readoutLength = 30


	# Second trigger mode, standard events
	# ------------------------------------

	m = s2Menu.mode(1)
	m.eventSize = 0
	m.eventToTrigger = 1
	m.eventType = 0x0
	m.tokenDelay = 30

	# Outputs, bank id 2, +0bx
	c = s2Menu.capture(1,0)
	c.delay = 0
	c.length = 5
	c.readoutLength = 30

	c = s2Menu.capture(1,1)
	c.delay = 0
	c.length = 5
	c.readoutLength = 30

	return s2Menu

menuMP = _makeMpMenu()

menuDemux = _makeDemuxMenu()

simpleDemux = _makeSimpleDemux()

simpleDemux5BX = _makeSimpleDemux5BX()

validationDemux5BX = _makeValidationDemux5BX()

simpleMPs = _makeSimpleMPs()

validationMps = _makeValidationMPs()
