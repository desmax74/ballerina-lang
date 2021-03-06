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
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/auth;

function testCreateConfigAuthProvider() returns (auth:ConfigAuthStoreProvider) {
    auth:ConfigAuthStoreProvider configAuthStoreProvider = new({});
    return configAuthStoreProvider;
}

function testAuthenticationOfNonExistingUser() returns (boolean) {
    auth:ConfigAuthStoreProvider configAuthStoreProvider = new({});
    return configAuthStoreProvider.authenticate("amila", "abc");
}

function testAuthenticationOfNonExistingPassword() returns (boolean) {
    auth:ConfigAuthStoreProvider configAuthStoreProvider = new({});
    return configAuthStoreProvider.authenticate("isuru", "xxy");
}

function testAuthentication() returns (boolean) {
    auth:ConfigAuthStoreProvider configAuthStoreProvider = new({});
    return configAuthStoreProvider.authenticate("isuru", "xxx");
}

function testReadScopesOfNonExistingUser() returns (string[]) {
    auth:ConfigAuthStoreProvider configAuthStoreProvider = new({});
    return configAuthStoreProvider.getScopes("amila");
}

function testReadScopesOfUser() returns (string[]) {
    auth:ConfigAuthStoreProvider configAuthStoreProvider = new({});
    return configAuthStoreProvider.getScopes("ishara");
}
