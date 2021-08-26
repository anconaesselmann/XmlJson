# XmlJson

[![CI Status](http://img.shields.io/travis/anconaesselmann/XmlJson.svg?style=flat)](https://travis-ci.org/anconaesselmann/XmlJson)
[![Version](https://img.shields.io/cocoapods/v/XmlJson.svg?style=flat)](http://cocoapods.org/pods/XmlJson)
[![License](https://img.shields.io/cocoapods/l/XmlJson.svg?style=flat)](http://cocoapods.org/pods/XmlJson)
[![Platform](https://img.shields.io/cocoapods/p/XmlJson.svg?style=flat)](http://cocoapods.org/pods/XmlJson)

**XmlJson is a declarative library for parsing `XML` documents.** By describing the structure of the underlying information we are spared tedious and error-prone conditional logic in decoding and encoding `XML` documents.

To run the `Example` playground that contains the code from the workings-out below clone the repo, run `pod install` in the `Example` directory and open the `Example.xcworkspace`. The `Example` playground contains all the examples from below.

To get started, import `XmlJson`:
```swift
import XmlJson
```

For this example we are going to use the contents of a `GPX` file (an `XML` file standard for storing location data.)

Let me quickly mention some of the strange aspects in regards to working with GPX files:

`TrackPoint`s `<trkpt>`, which make up `TrackSegment`s `<trkseg>` store location data within a `GPX` file using a strange combination of `XML` `element`s and `attribute`s. `TrackPoint`s thmeselves are `element`s and the associated elevation `<ele>` and a timestamp `<time>` are child `element`s within a `TrackPoint`. The latitude `lat` and longitude `lat` are `attribute`s of the `TrackPoint`. A `GPX` file can have multiple `TrackSegment`s, which are grouped inside a `TrackElement`, though *not* inside their own `element` containing only `TrackSegment`s, but annoyingly *alongside with other elements*, like the track's `name` element...

This makes for lot's of fun when it comes to representing `GPX` files as `JSON`.

Below are the contents of a `GPX` file created from location data collected with an iPhone and stored in the `GPX` file format using [SwiftGPX](https://github.com/anconaesselmann/SwiftGpx). We have one `Track` with two `TrackSegment`s with two `TrackPoint`s each:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<gpx
    xmlns="http://www.topografix.com/GPX/1/1" creator="SwiftGpx by Axel Ancona Esselmann" version="1.1"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
    <trk>
        <name>Peeler Lake - Noon Hike</name>
        <trkseg>
            <trkpt lat="38.123727" lon="-119.46705">
                <ele>2899.8</ele>
                <time>2021-06-03T20:25:26Z</time>
            </trkpt>
            <trkpt lat="38.123733" lon="-119.467049">
                <ele>2899.8</ele>
                <time>2021-06-03T20:25:27Z</time>
            </trkpt>
        </trkseg>
        <trkseg>
            <trkpt lat="38.123736" lon="-119.46705">
                <ele>2899.8</ele>
                <time>2021-06-03T20:25:29Z</time>
            </trkpt>
            <trkpt lat="38.123736" lon="-119.46705">
                <ele>2899.8</ele>
                <time>2021-06-03T20:25:30Z</time>
            </trkpt>
        </trkseg>
    </trk>
</gpx>
"""
```

Let's start by defining two helper-functions that will aid us in interpreting our latitude, longitude and elevation values as `Double`s, and will ensure that we later have a way to turn our [ISO 8601 timestamp](https://en.wikipedia.org/wiki/ISO_8601) into a `Date`:
```swift
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

func toDouble(_ any: Any) -> Any {
    Double(any as? String ?? "0") ?? 0
}

func dateStringToDouble(_ any: Any) -> Any {
    (dateFormatter.date(from: any as? String ?? "") ?? Date()).timeIntervalSince1970
}
```

Now let us use the declarative nature of `XmlJson` to describe the structure of our underlying `XML` document:
```swift
let xmlDict = XmlJson(
    xmlString: gpxFileContent,
    mappings: Set([
        .holdsArray(key: "trkseg", elementNames: "trkpt"),
        .holdsArray(key: "trk", elementNames: "trkseg"),
        .isTextNode(key: "ele"),
        .isTextNode(key: "time"),
        .isTextNode(key: "name")
    ]),
    // NOTE: Mappings HAVE to return a primitive type (String, Double, Int, Bool)
    transformations: Set<XmlTransformation>([
        XmlTransformation(key: "ele", map: toDouble),
        XmlTransformation(key: "lon", map: toDouble),
        XmlTransformation(key: "lat", map: toDouble),
        XmlTransformation(key: "time", map: dateStringToDouble)
    ])
)
```

Let's go over what we just did. First of all, we passed in the contents of our file as a `String`. We could have also passed in a `Data` instance and used the `XmlJson(xmlData:,mappings:,transformations:)` initializer.

Let's have a closer look the second parameter, `Set` of `mappings`:

It might not look like it, but this is the veggie-burger-and-potatoes of our task in turning the `XML` into something we can work with in `Swift` world.
Note that we only *declare what the content looks like* and are not getting bogged down with `switch`es, chains of `if else`s or any other conditional logic. With those three lines of code we took care all the elements and attributes we care about and all the messiness mentioned earlier inside the `<trk>` element where we have array elements (`TrackSegment`s) and non-array elements (like the `<name>` element) intermingled has gone away.

Let's look at two of those declarations in more detail:

```swift
.holdsArray(key: "trkseg", elementNames: "trkpt")
```
We are saying here that there is an element `<trkseg>` and it has a bunch of `<trkpt>`s inside. That is it. We don't care that `<trkseg>` also has other elements (namely `<name>`, which we will look at in a second) in the same DOM node. Anythin inside `<trkseg>` that is a `<trkpt>` will be gathered in an array containing just `<trkpt>` elements for us to use later.

About that `<name>` element:

```swift
.isTextNode(key: "name")
```

That is all we need. Somewhere there is an element named `name`, which is a [text node](https://www.w3schools.com/xml/dom_nodes.asp) (meaning we have text between the opening and closing tags)

Before we have a closer look at the set of `transformations` we also passed into the constructor, let's see what our efforts have yeilded so far.

With `xmlDict.dictionary` we now have access to a representation of the `GPX` file in the form of a `Dictionary` of type `[String: Any]`. This obviusly is not very `Swift`-friendly yet because of that pesky `Any` type, but let's see what we got so far using `xmlDict.jsonString`:

```json
{
  "gpx" : {
    "xsi:schemaLocation" : "http:\\/\\/www.topografix.com\\/GPX\\/1\\/1 http:\\/\\/www.topografix.com\\/GPX\\/1\\/1\\/gpx.xsd",
    "creator" : "SwiftGpx by Axel Ancona Esselmann",
    "version" : "1.1",
    "trk" : {
      "name" : "My Track",
      "trkseg_elements" : [
        {
          "trkpt_elements" : [
            {
              "lat" : 38.123727000000002,
              "lon" : -119.46705,
              "ele" : 2899.8000000000002,
              "time" : "2021-06-03T20:25:26Z"
            },
            {
              "time" : "2021-06-03T20:25:27Z",
              "ele" : 2899.8000000000002,
              "lat" : 38.123733000000001,
              "lon" : -119.467049
            }
          ]
        },
        {
          "trkpt_elements" : [
            {
              "lat" : 38.123736000000001,
              "lon" : -119.46705,
              "ele" : 2899.8000000000002,
              "time" : "2021-06-03T20:25:29Z"
            },
            {
              "ele" : 2899.8000000000002,
              "lon" : -119.46705,
              "time" : "2021-06-03T20:25:30Z",
              "lat" : 38.123736000000001
            }
          ]
        }
      ]
    },
    "xmlns" : "http:\\/\\/www.topografix.com\\/GPX\\/1\\/1",
    "xmlns:xsi" : "http:\\/\\/www.w3.org\\/2001\\/XMLSchema-instance"
  }
}
```

As you can see, our `<trkpt>` elements were gathered in an array and given the key `"trkseg_elements"`. At the same level we have `"name"`, which was intermingled with `<trkpt>`s. As you can see the rest of the `XML` structure was preserved and `JSON`ified. There are lot's of key-value pairs we didn't even describe! We didn't need to, because they behaved very `JSON` like (attributes inside elements) and our parser didn't need our help sorting those out.


Now that we know how `XmlJson` takes a `XML` document and parses it into `JSON`, let's have a closer look at the transformations we passed in.

```swift
Set<XmlTransformation>([
    XmlTransformation(key: "ele", map: toDouble),
    XmlTransformation(key: "lon", map: toDouble),
    XmlTransformation(key: "lat", map: toDouble),
    XmlTransformation(key: "time", map: dateStringToDouble)
]
```
The `XmlTransformation` object allows us to do whatever we would like with whatever was inside a text node or stored as an attribute key-value pair (as long as we return a primitive type (`String`, `Double`, `Int`, `Bool`.) More on that later. For the `lon`, `lat` attribute values and the `ele` text node contents we pass in our `toDouble` mapping function. All it does is turn a parsed `String` into a `Double` for us.

The mapping `dateStringToDouble` also returns a `Double`, but does some extra stuff for us: It starts with a [ISO 8601 timestamp](https://en.wikipedia.org/wiki/ISO_8601), turns that into a `Date` and returns the number of seconds since January 1st 1970. We will turn this back into a `Date` below. It might have been simpler to just leave the timestamp string alone and turn that into a `Date`, but this serves as a nice example that you can do any processing you want inside a `XmlTransformation`.

Now to why we have to return a primitive type:
To serialize our `[String: Any]` JSON array we rely on the old and trusty (and a bit rusty) `JSONSerialization` class and [those are the rules](https://developer.apple.com/documentation/foundation/jsonserialization).

We can turn this `JSON` monstrosity into a type-safe `Swift` object by replicating the dictionary structure with `Decodable` objects and decoding with JSONDecoder. Below I created a nested struct with that moslty replicates the `JSON` structure that our `XML` was squeezed into. Likely you won't need all properties or would like to do some rejiggling of properties and propertie names. Maybe some type conversions. You can obviously overwrite the custom `Decodable` (and likely `Encodable`) protocols to suit your needs. I chose to treat the `Document` struct below as an intermediary type, and in a bit we will be creating our final `Track` type, without leaking any of the odd `GPX`-file-structure into our beautiful and type-safe `Swift` world.

Here is `Document`, a mostly faithful translation of our `[String: Any]`:

```swift
struct Document: Codable {
    let gpx: Gpx

    struct Gpx: Codable {
        let creator: String
        let version: String
        let trk: Trk

        struct Trk: Codable {
            let name: String
            let trksegElements: [TrksegElement]

            struct TrksegElement: Codable {
                let trkptElements: [TrkptElement]

                struct TrkptElement: Codable {
                    let lat: Double
                    let lon: Double
                    let ele: Double
                    let time: Double

                    var date: Date { Date(timeIntervalSince1970: time) }
                }
            }
        }
    }
}
```
Note that we created a computed `var date: Date` property that lets us work with the location's timestamp as a `Date` instance and not the `Double` we turned it into.


For decoding we don't need a [String: Any] but instead an instance of `Data` (handling of optionals ommited for clarity):
```swift
let data = xmlDict.data

let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
decoder.dateDecodingStrategy = .secondsSince1970

let decoded = try decoder.decode(Document.self, from: data)
```

Depending on what your needs are you might be done at this point. As mentioned above I would like to continue working with a neat `Track` struck from here on out:

```swift
struct Track: Codable {
    let name: String
    let segments: [[Location]]

    struct Location: Codable {
        let lat: Double
        let lon: Double
        let ele: Double
        let timestamp: Date

        init(_ trkptElement: Document.Gpx.Trk.TrksegElement.TrkptElement) {
            lat = trkptElement.lat
            lon = trkptElement.lon
            ele = trkptElement.ele
            timestamp = trkptElement.date
        }
    }
}
```

A little extension for our Document to convert it into a Track instance:
```swift
extension Document {
    var track: Track {
        Track(
            name: gpx.trk.name,
            segments: gpx.trk.trksegElements.map {
                $0.trkptElements.map { Track.Location($0)  }
            }
        )
    }
}
```

And here we have it, messy XML to a clean (and now fully `Codable`) `Swift` type:

```swift
let track: Track = decoded.track
```

And of course we can serialize it with a JSONDecoder:
```swift
let encoder = JSONEncoder()
encoder.keyEncodingStrategy = .convertToSnakeCase
encoder.dateEncodingStrategy = .iso8601
encoder.outputFormatting = [.prettyPrinted]
let encodedTrack = try encoder.encode(decoded.track)
print(String(data: encodedTrack, encoding: .utf8)!)
```

which will look like this:
```json
{
  "name" : "My Track",
  "segments" : [
    [
      {
        "lat" : 38.123727000000002,
        "timestamp" : "2021-06-03T20:25:26Z",
        "lon" : -119.46705,
        "ele" : 2899.8000000000002
      },
      {
        "lat" : 38.123733000000001,
        "timestamp" : "2021-06-03T20:25:27Z",
        "lon" : -119.467049,
        "ele" : 2899.8000000000002
      }
    ],
    [
      {
        "lat" : 38.123736000000001,
        "timestamp" : "2021-06-03T20:25:29Z",
        "lon" : -119.46705,
        "ele" : 2899.8000000000002
      },
      {
        "lat" : 38.123736000000001,
        "timestamp" : "2021-06-03T20:25:30Z",
        "lon" : -119.46705,
        "ele" : 2899.8000000000002
      }
    ]
  ]
}
```

Where to go from here:

[XmlJson](https://github.com/anconaesselmann/XmlJson) also supports converting a `JSON` dictionary to an `XML` document. If you are interested in doing that, have a look at the full implementation of [SwiftGPX](https://github.com/anconaesselmann/SwiftGpx) (in particular [the XML handling](https://github.com/anconaesselmann/SwiftGpx/blob/master/SwiftGpx/Classes/XML.swift)), which can turn arrays of `CLLocation` instances into GPX files and vise versa. I might write that up eventually, but I think you have the tools now.

Also, if you are working with `CoreLocation` you probably don't want a custom `Location` struct but instead convert straight to a `CLLocation`. For any of those needs either use [SwiftGPX](https://github.com/anconaesselmann/SwiftGpx) or implement it yourself.

## Installation

XmlJson is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'XmlJson'
```

## Author

anconaesselmann, axel@anconaesselmann.com

## License

XmlJson is available under the MIT license. See the LICENSE file for more info.
