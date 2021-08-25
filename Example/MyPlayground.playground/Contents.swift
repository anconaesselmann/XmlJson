import XmlJson

let gpxFileContent = """
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<gpx
    xmlns="http://www.topografix.com/GPX/1/1" creator="SwiftGpx by Axel Ancona Esselmann" version="1.1"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
    <trk>
        <name>My Track</name>
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

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

let toDouble: (Any) -> Any = {
    Double($0 as? String ?? "0") ?? 0
}

let dateStringToDouble: (Any) -> Any = {
    (dateFormatter.date(from: $0 as? String ?? "") ?? Date()).timeIntervalSince1970
}

let xmlDict = XmlJson(
    xmlString: gpxFileContent, // Also an initializer that takes data
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

print("With xmlDict.dictionary you now have a representation of the GPX file in the format dictionary form: [String: Any]. If that is what you came here to do, awesome. For our example the resulting dictinary would look like this if converted to JSON (which xmlDict.jsonString will do for you):")

"""
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
"""

print("We can turn this monstrosity into a type-safe swift object by replicating the dictionary structure with Codable objects and decoding with JSONDecoder:")

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

print("For decoding we need the parsed document in data form:")
let data = xmlDict!.data!

print("And here we are doing vanilla JSONDecoder stuff to instantiate our Document:")
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
decoder.dateDecodingStrategy = .secondsSince1970

let decoded = try decoder.decode(Document.self, from: data)



print("So far we haven't really had a lot of controll for the organization of our object. We could have written a custom Decodable implementation for whatever final shape we want our GPX representation to take. Above I chose to create an intermediate Codable Document struct and now I will be doing the conversion to my final Track struct:")

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

print("And here we have it:")
let track: Track = decoded.track

print("And of course we can serialize it with a JSONDecoder:")
let encoder = JSONEncoder()
encoder.keyEncodingStrategy = .convertToSnakeCase
encoder.dateEncodingStrategy = .iso8601
encoder.outputFormatting = [.prettyPrinted]
let encodedTrack = try encoder.encode(decoded.track)
print(String(data: encodedTrack, encoding: .utf8)!)


print("This library also supports going from a dictionary to an XML document. If you are interested in doing that, have a look at the full implementation of SwiftGPX, which can turn turn arrays of CLLocation instances into GPX files and vise versa.")
