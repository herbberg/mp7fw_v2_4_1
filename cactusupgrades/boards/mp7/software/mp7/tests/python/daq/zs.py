
'''

Consistency checks:

 * wordsPerBx == 6: The ZS block works under the assumption that 1 BX worth of data is 6 32-bit words. *Any other* word-per-bx multiplicity leads to unpredictable results.
    * ZS can only be enabled globally. There is no provistion to enable it on a per-capture-mode basis.
    * So only wordsPerBx == 6 or wordsPerBx == 0 should be allowed.

'''
