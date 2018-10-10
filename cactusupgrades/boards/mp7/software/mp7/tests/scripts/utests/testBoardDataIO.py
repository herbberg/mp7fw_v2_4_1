import mp7


nLinks = 3
linkSize = 20


# Create the board data objetc
data = mp7.BoardData('mytest')

# Add links and payload
for lId in xrange(nLinks):

    # Create a link of the desired size
    ldata = mp7.LinkData(linkSize)

    # mark the link as strobed, so that the strobe is printed to file
    ldata.setStrobed(True)

    for k in xrange(linkSize):
        # Get a frame
        f = ldata[k]

        f.data = (lId << 8) + (k)

        # strobe high every other frame
        f.strobe = k % 2

        # valid for some frames only
        f.valid = (k > 3 and k <15)


    data.add(lId,ldata)

# Save to file
mp7.BoardDataFactory.saveToFile(data, 'mytest.txt')

# And read it back
data2 = mp7.BoardDataFactory.readFromFile('mytest.txt')

# is the content the same?
print 'data == data2? ', (data2 == data)

# print one frame from link 0
print 'data2, link 0, frame 4: ', data2[0][4]

# print the content of the second link from
for i,f in enumerate(data2[2]):
    print f