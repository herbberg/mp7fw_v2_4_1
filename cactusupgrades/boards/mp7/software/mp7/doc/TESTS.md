# MP7 Test infrastructure

## Organisation

Master script

```
${MP7_TESTS}/scripts/utests/mp7jeeves.py
```

Test code, based on python nose package

```
${MP7_TESTS}/python/mp7nose
```

Custom nose plugins

```
${MP7_TESTS}/python/mp7nose/plugins
```

MP7 tests modules

```
${MP7_TESTS}/python/mp7nose/utests/*_tests.py
```


Some notes:
mp7jeeves.py is a customisation to nosetests. The customisation required to pass the MP7 connection parameters to test code.
This is achieved through a custom nose plugin called mp7loader.py. The pluging passes stores the uhal connection parameters and the board name in mp7nose.env.

MP7 test plugins should inherit from mp7nose.TestUnit. TestUnit provides a few methods to easily access to MP7 and MMC controllers.


```
cd tests
source env.sh
```

Run all tests belonging to a module and produce a nice html report

```
mp7jeeves.py BOARDID  mp7nose.utests.buffer_tests --with-html
```

Run all tests known mp7 nose i.e. mp7nose submodules

```
mp7jeeves.py BOARDID mp7nose.utests --with-html
```

Run a specific test within a module

```
mp7jeeves.py BOARDID mp7nose.utests.buffer_tests:TestAlgoPlayback --with-html
```

Use custom connection file

```
mp7jeeves.py BOARDID --mp7-connections=c.xml mp7nose.utests
```
