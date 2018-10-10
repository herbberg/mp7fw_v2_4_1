import mp7

# from mp7 import Generics
# from mp7.orbit import Point, Metric


Generics = mp7.Generics
Point = mp7.orbit.Point
Metric = mp7.orbit.Metric

g = mp7.Generics()
g.bunchCount = 0xdec
g.clockRatio = 6
g.nRegions = 18

begin = Point(0x0,0)
end = Point(0xdeb, 5)

m = Metric(g)

a = Point(10, 3)
b = Point(3, 5)
c = Point(4, 0)
d = Point(0xd00,0)



print 'a =',a
print 'b =',b
print 'c =',c
print 'd =',d
print

print '--> Dist'
print 'dist(b,c) =', m.distance(b,c)
print 'dist(c,b) =', m.distance(c,b)
print 'dist(begin,end) =', m.distance(begin,end)
print


print '-> Sum p+p'
print 'a+b =',m.add(a, b)
print 'a+end =',m.add(a, end)
print 'end+a =',m.add(end,a)
print 'b-d =',m.add(b,d)
print

print '-> Sum p+x'
print 'a+1',m.add(a, 1)
print 'end+1 =',m.add(end,1)
print


print '-> Sub p-p'
print 'a-a =',m.sub(a,a)
print 'a-b =',m.sub(a,b)
print 'b-a =',m.sub(b,a)
print 'begin-a =',m.sub(begin,b)
print


print '-> Sub p-x'
print 'a-1 =',m.sub(a,1)


