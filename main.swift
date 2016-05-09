#!/usr/bin/swift
//
//  main.swift
//  ownLocal
//
//  Created by Lee Main on 5/4/16.
//  Copyright © 2016 LGEZSoftware. All rights reserved.
//

import Foundation

//#MARK: Helper Functions

//var headers = "id,uuid,name,address,address2,city,state,zip,country,phone,website,created_at"

/**
 Description: Function with returns a string representing the JSON equvilant for the object
 that is passed in.
 
 Parameter: 
    - object: (Dictionary or Array) which will be output into a JSON string.
 
 Notes:  This function relys heavily on a Foundation class to do all the heavy lifting.  Some
 research has shown that most language / runtime enviornments provide similar functionalily.
 One thing I did not see was a way to control the order that elements are output.
 
 
 Return: String?  JSON representation of object if successful, nil on failure.
 */
func getJSONFor(object: AnyObject) -> String?
{
    var jsonString : NSString?
    do
    {
        let rawData =  try NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions.PrettyPrinted)
        jsonString = NSString(data: rawData, encoding:NSUTF8StringEncoding)
    }
    catch
    { print("Exception:", #function, #line); return nil}
    
    return jsonString as String?
}

/**
 Description: Function with returns an array of strings which are contained in the passed in
 CSV string.  Note that this is used for the header fields, and assume no quotes or embedded
 commas exist in the passed in string.
 
 Parameter: 
    - aString: CSV String to be parsed.
 
 Return: [String] Array of strings contained in passed in string.
 */
func getFieldNamesFrom( aString: String) -> [String]
{
    var fieldNameArray = [String]()
    let scanner = NSScanner(string: aString)
    let termSet = NSCharacterSet(charactersInString: ",\r")
    
    var lookAhead : NSString? = ""
    var currentField : NSString? = ""

    repeat
    {
        // Put all characters up to the comma into currentField
        scanner.scanUpToCharactersFromSet(termSet, intoString: &currentField)
        
        if let currentField = currentField as String?
        {
            fieldNameArray.append( currentField)
        }
        else
        {
            print("Scanner Error:", #function, #line)
        }
        
        // Skip the comma
        scanner.scanCharactersFromSet(termSet, intoString: &lookAhead)
        
     } while !scanner.atEnd
    
    return fieldNameArray
}

/**
 Description: Function with returns corresponding dictionary based on the passed in
 CSV string and the associated keys array.
 
 Parameters: 
    - aString: String - CSV String to be parsed.
    - keys: [String]  - array of keys for created dictionary
 
 Notes:  Ideally, this function would populate the current record into a database for use 
 on the backend.  Swift currently does not have an interface into MySQL so I just build an in
 memory representation of the object data.  Once an interface into a database is provided the
 return from this method could be used to populate the database, vs keeping it around as is
 done in this implementation.
 
 
 Return: [String] Array of strings contained in passed in string.
 */
func getRecordFrom( aString: String, withKeys keys: [String]) -> [String:  AnyObject]
{
    var currentRecord = [String: AnyObject]()
    let scanner = NSScanner(string: aString)

    var termSet = NSCharacterSet()
    let commaSet = NSCharacterSet(charactersInString: ",\r")
    let quoteSet = NSCharacterSet(charactersInString: "\"")
    
    var lookAhead : NSString? = ""
    var currentField : NSString? = ""
    
    termSet = commaSet
    for aKey in keys
    {
        // Reset current field to empty to reset currentField if looking at empty field
        currentField = ""
        
        // Scan all characters up to the termination, could be comma, double quote, CR
        scanner.scanUpToCharactersFromSet(termSet, intoString: &currentField)
        
        if let currentField = currentField as String?
        {
            // ID field is the only field where an Integer is stored
            if aKey == "id" && currentField.characters.count > 0
            {
                currentRecord[ aKey] = Int(currentField)!
            }
            else
            {
                currentRecord[ aKey] = currentField
            }
        }
        else
        {
            print("Scanner Error:", #function, #line)
        }
        
        // If we were terminating on a quote, skip past it.
        if termSet === quoteSet
        {
            scanner.scanLocation = scanner.scanLocation + 1
        }
        
        // If we are not at the end, increment past the comma as well.
        if !scanner.atEnd
        {
            scanner.scanLocation = scanner.scanLocation + 1
        }
        else
        {
            break
        }
        
        // Checks to see if we are sitting on a double quote and sets the termination set 
        // accordingly
        if scanner.scanCharactersFromSet(quoteSet, intoString: &lookAhead)
        {
            // Deal with closing "
            termSet = quoteSet // allow comma to be accepted as a normal character
        }
        else
        {
            termSet = commaSet
        }
    }
    
    return currentRecord
}

/**
 Description: Function with returns the index of the matching object in the array or NSNotFound if not found.
 
 Parameters:
 - id: Int - ID to search for.
 - array: [ [String:String] ]  - array of keys for created dictionary
 
 Notes:  Ideally, this function would red information from the database, vs referencing the
 in memory object graph.
 
 Return: Index of object with ID matching parameter 1, or NSNotFound if not found.
 */
func indexOfObjectWithID( id : Int, forArray array: NSArray) -> Int
{
    var index : Int = NSNotFound
    
    index = array.indexOfObject(["id": id as AnyObject], inSortedRange: NSMakeRange(0, array.count), options: NSBinarySearchingOptions.FirstEqual)
        {
            (obj1 , obj2 ) -> NSComparisonResult in
            
            // Recover the integers from the dictionary
            let int1 = (obj1 as! [String: AnyObject ])["id"] as! Int
            let int2 = (obj2 as! [String: AnyObject ])["id"] as! Int
            
            if int1 < int2
            {
                return NSComparisonResult.OrderedAscending
            }
            
            if int1 > int2
            {
                return NSComparisonResult.OrderedDescending
            }
 
            else
            {
                return NSComparisonResult.OrderedSame
            }
        }
    
    return index
}

//#MARK: - Processing Starts here
var startTime = NSDate()

// array to hold requested search IDs
var idsToSearch : [ Int] = [ Int]()

// this array will all all of the data in a dictionary keyed by Strings, and can contain either
// an Integer (for the ID) or Strings for everything else.
var businessArray : [[String: AnyObject]] = [ [String: AnyObject] ]()

// Process the command line arguments.
// The file name has to be present to proceed, if no other
// arguments are present, then a dump of the entire file in JSON format will occur.  A list of 
// up to 5 IDs can be present which will be used to dump out the corresponding records.
switch Process.arguments.count
{
case 1: // Print help if just the command is typed at command line.
    print("Usage:\(Process.arguments[0]) <CSV File Path> [ID1 ID2 ... ID5]")
    exit(1)
    
case 2...7:
    for index in 2..<Process.arguments.count
    {
        var argID = Int(Process.arguments[index])
        if let argID = argID
        {
            idsToSearch.append(argID)
        }
        else
        {
            print("\(Process.arguments[index]) is not a valid ID")
            exit(1)
        }
    }
    
default:
    print("Can't have more than 5 search IDs")
    print("Usage:\(Process.arguments[0]) <CSV File Path> [ID1 ID2 ... ID5]")
    exit(1)
}

// Get first parameter and try to open it for reading.
var inputFilePath : NSString = Process.arguments[1]
inputFilePath = inputFilePath.stringByExpandingTildeInPath

guard let inputFileHandle = NSFileHandle.init(forReadingAtPath: inputFilePath as String) else
{
    print("\(inputFilePath) did not open.")
    exit(1)
}

// Read in the entire file, convert to a string, and separate by linefeed
let inData = inputFileHandle.readDataToEndOfFile()
let inString = NSString(data:inData,encoding:NSUTF8StringEncoding)! as String
let cvsStrings = inString.componentsSeparatedByString("\n")

// The first line of the CSV wil be stored in this array of strings.
var keys : [ String] = [String]()
var firstRecord = true

// Process the file, line by line
for aString in cvsStrings
{
    if firstRecord
    {
        firstRecord = false
        keys = getFieldNamesFrom(cvsStrings[0])
    }
    else
    {
        let aRecord = getRecordFrom(aString, withKeys: keys)
        
        // Only keep full records  (ie skip any blank lines which are incurred)
        if aRecord.count == keys.count
        {
            businessArray.append(aRecord)
        }
    }
}

// In order to perform a binary search, we must have a sorted array on the look field, ID in this case
var businessArraySort = businessArray.sort{ Int($0["id"]! as! NSNumber) < Int($1["id"]! as! NSNumber) }

businessArray =  [ [String: AnyObject] ]() // Free up any memory if possible

// The final model is a dictionary containing one item associated with the file.
var businesses : [String : AnyObject] = [String : AnyObject]()
businesses["businesses"] = businessArraySort

// If there are no specific search IDs, then dump out the JSON for entire datastore
// I did not provide a separate function for this, but as you can see the function based
// on this implementation would be trivial.  The more ideal solution would again reference
// a database and then retreive each record, convert to JSON, and then output that as the 
// return of the REST call.
if idsToSearch.count == 0
{
    var jsonString : NSString? = getJSONFor(businesses)
    if let jsonString = jsonString
    {
        print(jsonString)
    }
    else
    {
        print("Error generating JSON String")
    }
}
else
{   // Dumping out individual search ID requests
    
    // I need to use the API of the NSArray for the ID lookups.
    var nsArray = businessArraySort as NSArray
    
    for id in idsToSearch
    {
        // Perform the lookup
        var indexOfItemOfInterest = indexOfObjectWithID(id, forArray: nsArray)
        if indexOfItemOfInterest != NSNotFound
        {
            var jsonString : NSString? = getJSONFor(businessArraySort[indexOfItemOfInterest])
            if let jsonString = jsonString
            {
                print(jsonString)
            }
            else
            {
                print("Error generating JSON String")
            }
        }
        else
        {
            print("ID:\(id) not found")
        }
    }
}
