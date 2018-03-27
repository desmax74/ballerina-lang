import ballerina/net.http;
import ballerina/io;
import ballerina/net.http.endpoints;
import ballerina/auth;

endpoint endpoints:ApiEndpoint ep {
    port:9090
};

@http:ServiceConfig {
    basePath:"/echo"
}

service<http:Service> echo bind ep {
    @http:ResourceConfig {
        methods:["GET"],
        path:"/test"
    }
    @auth:Config {
        authentication:{enabled:true},
        scope:"scope2"
    }
    echo (endpoint client, http:Request req) {
        http:Response res = {};
        _ = client -> respond(res);
    }
}
