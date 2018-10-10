def getSettings():

    defaults = {}
    
    reset = {
        'clksrc':'internal',
        'clkcfg':'internal',
        'ttccfg': 'internal',
        'check': False,
        }
    
    defaults['reset'] = reset
    
    # Setup command defaults
    setup = {
        'internal': True,
        'fake': False,
        'fakesize': 100,
        'drain': None,
        'bxoffset':1,
        'watermarks':(32,16),
        }
    
    defaults['setup'] = setup
    
    # Stage1 Demo defaults
    s1demo = {
        'mode': 'algo',
        'chset': 'full',
        'src': 'counts',
        'add': 12,
        'inject': None,
        }
    
    defaults['s1demo'] = s1demo
    
    easylatency = {
        'rx'            : [],
        'tx'            : [0,1,2,3],
        # 'tx'            : range(36),
        'rxBank'        : 0,
        'txBank'        : 1,
        'algoLatency'   : 4,
        'masterLatency' : 0
    }

    defaults['easylatency'] = easylatency

    # Event capture defaults
    capture = {
        'nevents': 1,
        'outputpath': None,
        'bxs': [5],
        }
    
    defaults['capture'] = capture
    
    return defaults
