import ballerina/http;
import ballerinax/jaeger as _;

listener http:Listener httpListener = new (8080);

type Album readonly & record {|
    string id;
    string title;
    string artist;
    decimal price;
|};

table<Album> key(id) albums = table [
        {id: "1", title: "Blue Train", artist: "John Coltrane", price: 56.99},
        {id: "2", title: "Jeru", artist: "Gerry Mulligan", price: 17.99},
        {id: "3", title: "Sarah Vaughan and Clifford Brown", artist: "Sarah Vaughan", price: 39.99}
    ];

service /music on httpListener {
    resource function get albums() returns Album[] {
        return albums.toArray();
    }

    resource function get albums/[string id]() returns Album|http:NotFound {
        Album? album = albums[id];
        if album is () {
            return http:NOT_FOUND;
        } else {
            return album;
        }
    }

    resource function post albums(@http:Payload Album album) returns Album {
        albums.add(album);
        return album;
    }
}

type AlbumReport readonly & record {|
  decimal averagePrice;
  decimal maxPrice;
  int count;
|};

function getAveragePrice(decimal[] prices) returns decimal {
    match prices {
        var [first, ...rest] => {
            return decimal:avg(first, ...rest);
        }
        _ => {
            return 0;
        }
    }
}

service /reports on httpListener {
    resource function get albums() returns AlbumReport|error {
        http:Client music = check new ("http://localhost:8080/music");
        Album[] albums = check music->/albums();
        decimal[] prices = albums.map(a => a.price);
        AlbumReport report = {
            maxPrice: decimal:max(0, ...prices),
            averagePrice: getAveragePrice(prices),
            count: prices.length()
        };
        return report;
    }
}