import mp7


#    __  ___              ___ 
#   /  |/  /__ ___  __ __/ _ |
#  / /|_/ / -_) _ \/ // / __ |
# /_/  /_/\__/_//_/\_,_/_/ |_|
                            


# 1 mode, 1 capture
# No delay
menuA = mp7.ReadoutMenu(4,2,4)

menuA.bank(1).wordsPerBx = 6

# Triggers on every event
mode = menuA.mode(0)

mode.eventSize = 0
mode.eventToTrigger = 1
mode.eventType = 0xc0
mode.tokenDelay = 70

# Even, bank id 1, +0bx
c = mode[0]
c.enable = True
c.id = 0x1
c.bankId = 0x1
c.length = 1
c.delay = 0
c.readoutLength = 6


#    __  ___              ___ 
#   /  |/  /__ ___  __ __/ _ |
#  / /|_/ / -_) _ \/ // / __ |
# /_/  /_/\__/_//_/\_,_/_/ |_|
                            


# 1 mode, 1 capture
# No delay
menuAprime = mp7.ReadoutMenu(4,2,4)

menuAprime.bank(0).wordsPerBx = 0
menuAprime.bank(1).wordsPerBx = 6
menuAprime.bank(2).wordsPerBx = 0
menuAprime.bank(3).wordsPerBx = 0

# Triggers on every event
mode = menuAprime.mode(0)

mode.eventSize = 0
mode.eventToTrigger = 1
mode.eventType = 0xc0
mode.tokenDelay = 70

# Even, bank id 1, +0bx
c = mode[1]
c.enable = True
c.id = 0x1
c.bankId = 0x1
c.length = 1
c.delay = 0
c.readoutLength = 6


#    __  ___              ___   ____     __ 
#   /  |/  /__ ___  __ __/ _ | / __/__ _/ /_
#  / /|_/ / -_) _ \/ // / __ |/ _// _ `/ __/
# /_/  /_/\__/_//_/\_,_/_/ |_/_/  \_,_/\__/ 
                                          
# 1 bank, 1 mode, 1 capture
# No delay
menuAFat = mp7.ReadoutMenu(4,2,4)

menuAFat.bank(1).wordsPerBx = 6


# First Mode
# Triggers on every event
mode = menuAFat.mode(0)

mode.eventSize = 0
mode.eventToTrigger = 1
mode.eventType = 0xfa
mode.tokenDelay = 70


# Even, bank id 1, +0bx
c = mode[0]
c.enable = True
c.id = 0x1
c.bankId = 0x1
c.length = 3
c.delay = 0
c.readoutLength = 18


#    __  ___              ___ 
#   /  |/  /__ ___  __ __/ _ )
#  / /|_/ / -_) _ \/ // / _  |
# /_/  /_/\__/_//_/\_,_/____/ 

# Menu B
# 2 banks, 1 mode, 2 captures
# No delay
menuB = mp7.ReadoutMenu(4,2,4)

menuB.bank(1).wordsPerBx = 6
menuB.bank(2).wordsPerBx = 6

# First Mode
# Triggers every other event
mode = menuB.mode(0)

mode.eventSize = 0
mode.eventToTrigger = 1
mode.eventType = 0xc0
mode.tokenDelay = 70


# Even, bank id 1, +0bx
c = mode[0]
c.enable = True
c.id = 0x1
c.bankId = 0x1
c.length = 1
c.delay = 0
c.readoutLength = 6

c = mode[1]
c.enable = True
c.id = 0x2
c.bankId = 0x2
c.length = 1
c.delay = 0
c.readoutLength = 6


#    __  ___              _____
#   /  |/  /__ ___  __ __/ ___/
#  / /|_/ / -_) _ \/ // / /__  
# /_/  /_/\__/_//_/\_,_/\___/  

# 2 band ids                         
# 2 modes
# - mode 0 even events
# - mode 1 all events
# 2 bx delay for all captures (stage1 style)
menuC = mp7.ReadoutMenu(4,2,4)

menuC.bank(1).wordsPerBx = 6
menuC.bank(2).wordsPerBx = 6

# First Mode
# Triggers every other event
mode = menuC.mode(0)

mode.eventSize = 0
mode.eventToTrigger = 2
mode.eventType = 0xc0
mode.tokenDelay = 70


# Even, bank id 1, +0bx
c = mode[0]
c.enable = True
c.id = 0x1
c.bankId = 0x1
c.length = 1
c.delay = 2 #2 # 0+2 bx
c.readoutLength = 6

c = mode[1]
c.enable = True
c.id = 0x2
c.bankId = 0x2
c.length = 1
c.delay = 2 # 2 # 0+2 bx
c.readoutLength = 6


# Second Mode
mode = menuC.mode(1)

mode.eventSize = 0
mode.eventToTrigger = 1
mode.eventType = 0xde
mode.tokenDelay = 70


# Even, bank id 1, +0bx
c = mode[0]
c.enable = True
c.id = 0x1
c.bankId = 0x1
c.length = 1
c.delay = 2 #2 # 0+2 bx
c.readoutLength = 6

c = mode[1]
c.enable = True
c.id = 0x2
c.bankId = 0x2
c.length = 1
c.delay = 2 # 2 # 0+2 bx
c.readoutLength = 6

#           __  ___              ___ 
#  ___ ___ /  |/  /__ ___  __ __/ _ |
# /_ /(_-</ /|_/ / -_) _ \/ // / __ |
# /__/___/_/  /_/\__/_//_/\_,_/_/ |_|
                                   
                                   
zsMenuA = mp7.ZeroSuppressionMenu()

zsMenuA.setValidationMode(0x0)
zsMenuA[1].enable = True
zsMenuA[1].data = [0xff]*6

                                   
zsMenuA1 = mp7.ZeroSuppressionMenu()

zsMenuA1.setValidationMode(0x0)
zsMenuA1[1].enable = True
zsMenuA1[1].data = [0xfd]*6


#    __  ___              ___ 
#   /  |/  /__ ___  __ __/ _ )
#  / /|_/ / -_) _ \/ // / _  |
# /_/  /_/\__/_//_/\_,_/____/ 

# Menu B
# 2 banks, 1 mode, 2 captures
# No delay
menuErr = mp7.ReadoutMenu(4,2,4)

menuErr.bank(1).wordsPerBx = 6
menuErr.bank(2).wordsPerBx = 6

# First Mode
# Triggers every other event
mode = menuErr.mode(0)

mode.eventSize = 0
mode.eventToTrigger = 1
mode.eventType = 0xc0
mode.tokenDelay = 70


# Even, bank id 1, +0bx
c = mode[0]
c.enable = True
c.id = 0x1
c.bankId = 0x1
c.length = 1
c.delay = 0
c.readoutLength = 6

c = mode[1]
c.enable = False
c.id = 0x2
c.bankId = 0x2
c.length = 1
c.delay = 0
c.readoutLength = 6

c = mode[2]
c.enable = True
c.id = 0x2
c.bankId = 0x2
c.length = 1
c.delay = 0
c.readoutLength = 6

c = mode[3]
c.enable = True
c.id = 0x2
c.bankId = 0x2
c.length = 1
c.delay = 0
c.readoutLength = 6
