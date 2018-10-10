def getSettings():
    defaults = {}
    reset = {
        "clksrc":"internal",
        "clkcfg":"internal",
        "ttccfg": "internal",
        "check": False,
        }
    
    defaults["reset"] = reset
        
    return defaults
