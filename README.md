# ol
Repository to be used for ownLocal submission.

## Notes
As I mentioned to Dan in our screening conversation. I have no backend web programming experience.  This will be easy to see from my implementation of the project, that I just do not know how to do that yet. 

When I first read the project guidelines, I was like, yep don’t know how to do that and I almost replied right then that I just did not have experience to do the project. I am sure I could have found someone who could have coached me through the web parts of the exercise, but then that would not have been me, and really would not have been an accurate assessment of my current capabilities.  After sleeping on it a night, I decided to do what I could to demonstrate at least some of my coding abilities and see where that leaves us.

So at first, I started by creating a command line compiled program which would parse the CSV file and output the corresponding JSON for the two scenarios.  About the time I got the CSV file parsed correctly, it became pretty apparent that I would ideally need to store everything from the CSV into a corresponding data base which can then be accessed via one of two web URLs, one for each REST API.  You can certainly tell that I am not doing that.  So I watched videos about REST over the weekend, but could not get a good feel that  and toyed with not turning anything in at all, but decided that I would turn in what I have here and go on from there.  I have only about 12 hours of work in my implementation and feel very confident that if I just knew how to interact with the DB and understood the web interface stuff, I would be able to bang out the rest of the code and test it in one more day. 

One really nice thing that came out of this exercise for me, was the running of just the Swift source file as if it were a Perl & Python (others languages which I never had to need to learn, but understand it is big in your world of development) script. 

## Instructions
Simply run main.swift at the command line with the first parameter being the complete path to the csv file.  You can add up to 5 id's which will be returned via stdout in JSON format for each ID you are requesting.  If you provide no ID's the entire object graph is returned in JSON.

### Complete Object Graph
For a full dump of the CSV file in JSON format enter the following at the Mac OS X command line.

./main.swift 50k_businesses.csv   

### Individual ID query
To dump just certain IDs enter something like the following, up to 5 ids:

/main.swift 50k_businesses.csv   2314 3156

If you have any other questions or comments, feel free to contact me at leeshipman@mac.com

Thanks for your interest and time.
Lee
