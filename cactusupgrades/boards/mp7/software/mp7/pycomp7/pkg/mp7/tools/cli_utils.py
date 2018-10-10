import argparse
import mp7

def convert( val ):
    if val is None:
        return None
    elif val.startswith("0x") or val.startswith("0X"):
        return int(val,16)
    elif val.startswith("0"):
        return int(val,8)
    else:
        return int(val)

# custom class to validate 'exec' variables
class ExecVarAction(argparse.Action):

    def __call__(self, parser, namespace, values, option_string=None):
        errors=[ "'%s'"%v for v in values if '=' not in v]
        if len(errors): #raise ValueError(self.dest,'stoca')
            parser.error('The following arguments are not in <key>=<value> format: %s' % (','.join(errors)) )
        setattr(namespace, self.dest, values)


class BxRangeTupleAction(argparse.Action):
    ''' Converts --<option>=bx,cycle:bx,cycle into 2 tuples'''

    def __call__(self, parser, namespace, values, option_string=None):
        import re
        
        h = '(0x)?[0-9a-f]+'
        xpr = '(%s)(,(%s))?(:(%s)(,(%s))?)?' % (h,h,h,h)
        m = re.match(xpr, values)

        if values != m.group():
            parser.error('Malformed BX range %s. Expected format bx,cycle(:bx,cycle)')

        firstBx,firstCyc,lastBx,lastCyc = [ convert(m.groups()[i]) for i in xrange(0,12,3) ]

        if (
            (firstBx is None and firstCyc is not None) or 
            (lastBx is None and lastCyc is not None )
            ):
            parser.error('WTF!!!')

        first = mp7.orbit.Point( firstBx, firstCyc if firstCyc is not None else 0)
        last = mp7.orbit.Point( lastBx, lastCyc if lastCyc is not None else 0) if lastBx is not None else None

        setattr(namespace, self.dest, (first,last) )


class OrbitPointAction(argparse.Action):

    def __call__(self, parser, namespace, values, option_string=None):

        tokens = values.split(',')
        if len(tokens) == 2:
            try:
                bx,cycle=( convert(t) for t in tokens )
            except StandardError as e:
                parser.error(str(e))
        elif len(tokens) == 1:
            try:
                bx,cycle = convert(tokens[0]),0
            except StandardError as e:
                parser.error(str(e))
        else:
            raise ValueError('Wrong format. Should be: %s=bx,cycle' % self.dest)

        setattr(namespace, self.dest, (bx,cycle) )


class IntListAction(argparse.Action):
    def __init__(self, *args, **kwargs):
        super(IntListAction, self).__init__(*args, **kwargs)
        # self._var  = var
        # self._sep  = sep
        # self._dash = dash
        self._sep  = ','
        self._dash = '-'

    def __call__(self, parser, namespace, values, option_string=None):

        numbers=[]
        items = values.split(self._sep)
        for item in items:
            nums = item.split(self._dash)
            if len(nums) == 1:
                # single number
                numbers.append(int(item))
            elif len(nums) == 2:
                i = int(nums[0])
                j = int(nums[1])
                if i > j:
                    parser.error('Invalid interval '+item)
                numbers.extend(range(i,j+1))
            else:
               parser.error('Malformed option (comma separated list expected): %s' % values)

        setattr(namespace, self.dest, numbers)


class IntPairAction(argparse.Action):
    def __init__(self, *args, **kwargs):
        super(IntPairAction, self).__init__(*args, **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):

        tokens = values.split(',')
        print tokens
        if len(tokens) == 2:
            result = (int(t) for t in tokens)
        else:
            raise ValueError('Wrong format. Should be: %s=first,last' % self.dest)

        setattr(namespace, self.dest, result)

class HdrFormatterAction(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        # print 'aaaa'

        if values.count(',') != 1:
            raise ValueError('The header formatter parameter must be a (no-)strip/(no-)insert pair')
        strip,insert = values.split(',')

        if strip not in ['strip','no-strip']:
            raise ValueError('The first header formatter paramter can either be strip or no-strip')
        if insert not in ['insert','no-insert']:
            raise ValueError('The first header formatter paramter can either be insert or no-insert')

        result = {}
        result['strip'] = (strip == 'strip')
        result['insert'] = (insert == 'insert')
        setattr(namespace, self.dest, result)


class ValidFormatterAction(argparse.Action):
    ''' Converts --<option>=bx,cycle:bx,cycle into 2 tuples'''
    def __call__(self, parser, namespace, values, option_string=None):
        import re

        if values == 'disable':
            setattr(namespace, self.dest, values)
            return

        h = '(0x)?[0-9a-f]+'
        xp = '(%s),(%s):(%s),(%s)' % (h,h,h,h)
        m = re.search(xp, values)

        if m:
            start_bx,start_cyc,stop_bx,stop_cyc = [ convert(m.groups()[i]) for i in xrange(0,8,2) ]
        else:
            raise ValueError('Wrong format. Should be: %s=bx,cycle:bx,cycle' % self.dest)

        result = {}
        result['start'] = (start_bx,start_cyc)
        result['stop']  = (stop_bx,stop_cyc)
        setattr(namespace, self.dest, result)



class BC0FormatterAction(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        if values == 'disable':
            setattr(namespace, self.dest, values)
        else:
            setattr(namespace, self.dest, convert(values))
