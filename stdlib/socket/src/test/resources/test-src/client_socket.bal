// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/socket;

function oneWayWrite(string msg) {
    socket:Client socketClient = new({ host: "localhost", port: 47826 });
    byte[] msgByteArray = msg.toByteArray("utf-8");
    var writeResult = socketClient->write(msgByteArray);
    if (writeResult is int) {
        io:println("Number of bytes written: ", writeResult);
    } else {
        panic writeResult;
    }
    var closeResult = socketClient->close();
    if (closeResult is error) {
        io:println(closeResult.detail().message);
    } else {
        io:println("Client connection closed successfully.");
    }
}

function shutdownWrite(string firstMsg, string secondMsg) returns error? {
    socket:Client socketClient = new({ host: "localhost", port: 47826 });
    byte[] msgByteArray = firstMsg.toByteArray("utf-8");
    var writeResult = socketClient->write(msgByteArray);
    if (writeResult is int) {
        io:println("Number of bytes written: ", writeResult);
    } else {
        panic writeResult;
    }
    var shutdownResult = socketClient->shutdownWrite();
    if (shutdownResult is error) {
        panic shutdownResult;
    }
    msgByteArray = secondMsg.toByteArray("utf-8");
    writeResult = socketClient->write(msgByteArray);
    if (writeResult is int) {
        io:println("Number of bytes written: ", writeResult);
    } else {
        var closeResult = socketClient->close();
        if (closeResult is error) {
            io:println(closeResult.detail().message);
        } else {
            io:println("Client connection closed successfully.");
        }
        return writeResult;
    }
    return;
}

function echo(string msg) returns string {
    socket:Client socketClient = new({ host: "localhost", port: 47826 });
    string returnStr = "";
    byte[] msgByteArray = msg.toByteArray("utf-8");
    var writeResult = socketClient->write(msgByteArray);
    if (writeResult is int) {
        io:println("Number of bytes written: ", writeResult);
    } else {
        io:println("echo panic", writeResult);
        panic writeResult;
    }
    var result = socketClient->read();
    if (result is (byte[], int)) {
        var (content, length) = result;
        if (length > 0) {
            var str = getString(content);
            if (str is string) {
                returnStr = untaint str;
            } else {
                io:println(str.detail().message);
            }
            var closeResult = socketClient->close();
            if (closeResult is error) {
                io:println(closeResult.detail().message);
            } else {
                io:println("Client connection closed successfully.");
            }
        } else {
            io:println("Client close: ", socketClient.remotePort);
        }
    } else {
        io:println(result);
    }
    return returnStr;
}

function getString(byte[] content) returns string|error {
    io:ReadableByteChannel byteChannel = io:createReadableChannel(content);
    io:ReadableCharacterChannel characterChannel = new io:ReadableCharacterChannel(byteChannel, "UTF-8");
    return characterChannel.read(50);
}

function invalidReadParam() returns (byte[], int)|error {
    socket:Client socketClient = new({ host: "localhost", port: 47826 });
    return trap socketClient->read(length = 0);
}

function invalidAddress() returns error? {
    error? result = trap createClient();
    return result;
}

function createClient() {
    socket:Client socketClient = new({ host: "localhost", port: 43434 });
}
