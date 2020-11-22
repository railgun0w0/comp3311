# COMP3311 20T3 Ass3 ... Python helper functions
# add here any functions to share between Python scripts 

#print name and birth year and death year
def printnameandbirth(name):
    string = ''
    if name[1] == None and  name[2] == None:
        string = f'{name[0]} (???)'
    elif name[1] == None and name[2] != None:
        string = f'{name[0]} (-{ name[2]})'
    elif name[1] != None and name[2] == None:
        string = f'{name[0]} ({name[1]}-)'
    else:
        string = f'{name[0]} ({name[1]}-{ name[2]})'
    return string

# check argc number
def checkargv(argc,usage):
    if argc < 2:
        print(usage)
        exit()
    if argc > 3:
        print(usage)
        exit()

#check year whether is dig
def checkyear(year,usage):
    if year.isdigit() == False:
        print(usage)
        exit()

