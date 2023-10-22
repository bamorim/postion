import ballerina/http;
import ballerina/jwt;
import ballerinax/jaeger as _;

listener http:Listener httpListener = new (8080);

type RefreshTokenResponse readonly & record {|
    string token;
|};

type RefreshTokenRequest readonly & record {|
    string refresh_token;
|};

jwt:IssuerConfig issuerConfig = {
    username: "postion",
    issuer: "extsvc",
    audience: "extsvc",
    expTime: 3600,
    signatureConfig: {
        config: {
            keyFile: "jwt.key"
        }
    }
};

service /tokens on httpListener {
    resource function post refresh(@http:Payload RefreshTokenRequest request) returns RefreshTokenResponse|http:Forbidden|error {
        if request.refresh_token == "secure_token" {
            return {token: check jwt:issue(issuerConfig)};
        } else {
            return http:FORBIDDEN;
        }
    }
}

type FlagRequest readonly & record {|
    string userId;
|};

type FlagResponse readonly & record {|
    boolean enabled;
|};

type FlagOverride readonly & record {|
    readonly string id;
    boolean enabled;
|};

type Flag readonly & record {|
    readonly string name;
    boolean defaultEnabled;
    table<FlagOverride> key(id) overrides;
|};

table<Flag> key(name) flags = table [
    {
        name: "TREE_VIEW",
        defaultEnabled: true,
        overrides: table [
        {id: "1", enabled: false}
    ]
    }
];

@http:ServiceConfig {
    auth: [
        {
            jwtValidatorConfig: {
                issuer: "extsvc",
                audience: "extsvc",
                signatureConfig: {
                    certFile: "jwt.crt"
                },
                scopeKey: "scp"
            }
        }
    ]
}
service /flags on httpListener {
    resource function post [string flagName]/evaluate(@http:Payload FlagRequest request) returns FlagResponse|http:NotFound {
        Flag? flag = flags[flagName];
        if (flag is ()) {
            return http:NOT_FOUND;
        }
        FlagOverride? override = flag.overrides[request.userId];

        if (override is ()) {
            return {enabled: flag.defaultEnabled};
        } else {
            return {enabled: override.enabled};
        }
    }
}
