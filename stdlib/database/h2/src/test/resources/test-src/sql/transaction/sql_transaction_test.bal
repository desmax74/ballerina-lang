// Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/h2;
import ballerina/io;
import ballerina/runtime;
import ballerina/sql;
import ballerina/transactions;

type ResultCount record {
    int COUNTVAL;
};

function testLocalTransaction() returns (int, int, boolean, boolean) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = 0;
    int count;
    boolean committedBlockExecuted = false;
    boolean abortedBlockExecuted = false;
    transaction {
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                values ('James', 'Clerk', 200, 5000.75, 'USA')");
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                values ('James', 'Clerk', 200, 5000.75, 'USA')");
    } onretry {
        returnVal = -1;
    } committed {
        committedBlockExecuted = true;
    } aborted {
        abortedBlockExecuted = true;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 200", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal, count, committedBlockExecuted, abortedBlockExecuted);
}

function testTransactionRollback() returns (int, int, boolean) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = 0;
    int count;
    boolean stmtAfterFailureExecuted = false;

    transaction {
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,
                creditLimit,country) values ('James', 'Clerk', 210, 5000.75, 'USA')");
        _ = testDB->update("Insert into Customers2 (firstName,lastName,registrationID,
                creditLimit,country) values ('James', 'Clerk', 210, 5000.75, 'USA')");
        stmtAfterFailureExecuted = true;

    } onretry {
        returnVal = -1;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 210", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal, count, stmtAfterFailureExecuted);
}

function testLocalTransactionUpdateWithGeneratedKeys() returns (int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = 0;
    int count;
    transaction {
        _ = testDB->update("Insert into Customers
        (firstName,lastName,registrationID,creditLimit,country) values ('James', 'Clerk', 615, 5000.75, 'USA')");
        _ = testDB->update("Insert into Customers
        (firstName,lastName,registrationID,creditLimit,country) values ('James', 'Clerk', 615, 5000.75, 'USA')");
    } onretry {
        returnVal = -1;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 615", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal, count);
}

function testTransactionRollbackUpdateWithGeneratedKeys() returns (int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = 0;
    int count;

    transaction {
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,
                creditLimit,country) values ('James', 'Clerk', 618, 5000.75, 'USA')");
        _ = testDB->update("Insert into Customers2 (firstName,lastName,registrationID,
                creditLimit,country) values ('James', 'Clerk', 618, 5000.75, 'USA')");
    } onretry {
        returnVal = -1;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 618", ResultCount);

    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal, count);
}

function testLocalTransactionStoredProcedure() returns (int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = 0;
    int count;

    transaction {
        _ = testDB->call("{call InsertPersonDataSuccessful(?, ?)}", (), 628, 628);
        _ = testDB->call("{call InsertPersonDataSuccessful(?, ?)}", (), 628, 628);
    } onretry {
        returnVal = -1;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 628", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal, count);
}

function testLocalTransactionRollbackStoredProcedure() returns (int, int, int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 3 }
    });

    int returnVal = 0;
    int count1;
    int count2;
    int count3;

    transaction {
        _ = testDB->call("{call InsertPersonDataSuccessful(?, ?)}", (), 629, 629);
        _ = testDB->call("{call InsertPersonDataFailure(?, ?)}", (), 631, 632);
    } onretry {
        returnVal = -1;
    }
    //check whether update action is performed
    var dt1 = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 629",
        ResultCount);
    var dt2 = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 631",
        ResultCount);
    var dt3 = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 632",
        ResultCount);

    count1 = getTableCountValColumn(dt1);
    count2 = getTableCountValColumn(dt2);
    count3 = getTableCountValColumn(dt3);
    _ = testDB.stop();
    return (returnVal, count1, count2, count3);
}

function testLocalTransactionBatchUpdate() returns (int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = 0;
    int count;

    //Batch 1
    sql:Parameter para1 = { sqlType: sql:TYPE_VARCHAR, value: "Alex" };
    sql:Parameter para2 = { sqlType: sql:TYPE_VARCHAR, value: "Smith" };
    sql:Parameter para3 = { sqlType: sql:TYPE_INTEGER, value: 611 };
    sql:Parameter para4 = { sqlType: sql:TYPE_DOUBLE, value: 3400.5 };
    sql:Parameter para5 = { sqlType: sql:TYPE_VARCHAR, value: "Colombo" };
    sql:Parameter?[] parameters1 = [para1, para2, para3, para4, para5];

    //Batch 2
    para1 = { sqlType: sql:TYPE_VARCHAR, value: "Alex" };
    para2 = { sqlType: sql:TYPE_VARCHAR, value: "Smith" };
    para3 = { sqlType: sql:TYPE_INTEGER, value: 611 };
    para4 = { sqlType: sql:TYPE_DOUBLE, value: 3400.5 };
    para5 = { sqlType: sql:TYPE_VARCHAR, value: "Colombo" };
    sql:Parameter?[] parameters2 = [para1, para2, para3, para4, para5];

    transaction {
        _= testDB->batchUpdate("Insert into Customers
        (firstName,lastName,registrationID,creditLimit,country) values (?,?,?,?,?)", parameters1, parameters2);
        _ = testDB->batchUpdate("Insert into Customers
        (firstName,lastName,registrationID,creditLimit,country) values (?,?,?,?,?)", parameters1, parameters2);
    } onretry {
        returnVal = -1;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 611", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal, count);
}

function testLocalTransactionRollbackBatchUpdate() returns (int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = 0;
    int count;

    //Batch 1
    sql:Parameter para1 = { sqlType: sql:TYPE_VARCHAR, value: "Alex" };
    sql:Parameter para2 = { sqlType: sql:TYPE_VARCHAR, value: "Smith" };
    sql:Parameter para3 = { sqlType: sql:TYPE_INTEGER, value: 612 };
    sql:Parameter para4 = { sqlType: sql:TYPE_DOUBLE, value: 3400.5 };
    sql:Parameter para5 = { sqlType: sql:TYPE_VARCHAR, value: "Colombo" };
    sql:Parameter?[] parameters1 = [para1, para2, para3, para4, para5];

    //Batch 2
    para1 = { sqlType: sql:TYPE_VARCHAR, value: "Alex" };
    para2 = { sqlType: sql:TYPE_VARCHAR, value: "Smith" };
    para3 = { sqlType: sql:TYPE_INTEGER, value: 612 };
    para4 = { sqlType: sql:TYPE_DOUBLE, value: 3400.5 };
    para5 = { sqlType: sql:TYPE_VARCHAR, value: "Colombo" };
    sql:Parameter?[] parameters2 = [para1, para2, para3, para4, para5];

    transaction {
        _ = testDB->batchUpdate("Insert into Customers
        (firstName,lastName,registrationID,creditLimit,country) values (?,?,?,?,?)", parameters1, parameters2);
        _ = testDB->batchUpdate("Insert into Customers2
        (firstName,lastName,registrationID,creditLimit,country) values (?,?,?,?,?)", parameters1, parameters2);
    } onretry {
        returnVal = -1;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 612", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal, count);
}

function testTransactionAbort() returns (int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = -1;
    int count;
    transaction {
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                            values ('James', 'Clerk', 220, 5000.75, 'USA')");

        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                            values ('James', 'Clerk', 220, 5000.75, 'USA')");
        int i = 0;
        if (i == 0) {
            abort;
        }
        returnVal = 0;
    } onretry {
        returnVal = -1;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 220", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal, count);
}

int testTransactionErrorPanicRetVal = 0;
function testTransactionErrorPanic() returns (int, int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = 0;
    int catchValue = 0;
    int count;
    var ret = trap testTransactionErrorPanicHelper(testDB);
    if (ret is error) {
        catchValue = -1;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 260", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (testTransactionErrorPanicRetVal, catchValue, count);
}

function testTransactionErrorPanicHelper(h2:Client testDB) {
    int returnVal = 0;
    transaction {
        _ = testDB->update("Insert into Customers (firstName,lastName,
                              registrationID,creditLimit,country) values ('James', 'Clerk', 260, 5000.75, 'USA')");
        int i = 0;
        if (i == 0) {
            error e =  error("error");
            panic e;
        }
    } onretry {
        testTransactionErrorPanicRetVal = -1;
    }
}

function testTransactionErrorPanicAndTrap() returns (int, int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = 0;
    int catchValue = 0;
    int count;
    transaction {
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,
                 creditLimit,country) values ('James', 'Clerk', 250, 5000.75, 'USA')");
        var ret = trap testTransactionErrorPanicAndTrapHelper(0);
        if (ret is error) {
            catchValue = -1;
        }
    } onretry {
        returnVal = -1;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 250", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal, catchValue, count);
}

function testTransactionErrorPanicAndTrapHelper(int i) {
    if (i == 0) {
        error err = error("error" );
        panic err;
    }
}

function testTransactionCommitted() returns (int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = 1;
    int count;
    transaction {
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,
               country) values ('James', 'Clerk', 300, 5000.75, 'USA')");
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,
               country) values ('James', 'Clerk', 300, 5000.75, 'USA')");
    } onretry {
        returnVal = -1;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 300", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal, count);
}

function testTwoTransactions() returns (int, int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal1 = 1;
    int returnVal2 = 1;
    int count;
    transaction {
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                            values ('James', 'Clerk', 400, 5000.75, 'USA')");
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                            values ('James', 'Clerk', 400, 5000.75, 'USA')");
    } onretry {
        returnVal1 = 0;
    }

    transaction {
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                            values ('James', 'Clerk', 400, 5000.75, 'USA')");
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                            values ('James', 'Clerk', 400, 5000.75, 'USA')");
    } onretry {
        returnVal2 = 0;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 400", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal1, returnVal2, count);
}

function testTransactionWithoutHandlers() returns (int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    transaction {
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country) values
                                           ('James', 'Clerk', 350, 5000.75, 'USA')");
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country) values
                                           ('James', 'Clerk', 350, 5000.75, 'USA')");
    }

    int count;
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 350", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return count;
}

function testLocalTransactionFailed() returns (string, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    string a = "beforetx";
    int count = -1;

    var ret = trap testLocalTransactionFailedHelper(a, testDB);
    if (ret is string) {
        a = ret;
    } else {
        a = a + " trapped";
    }
    a = a + " afterTrx";
    var dtRet = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 111", ResultCount);
    count = getTableCountValColumn(dtRet);
    _ = testDB.stop();
    return (a, count);
}

function testLocalTransactionFailedHelper(string status, h2:Client testDB) returns string {
    string a = status;
    transaction with retries = 4 {
        a = a + " inTrx";
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                        values ('James', 'Clerk', 111, 5000.75, 'USA')");
        _ = testDB->update("Insert into Customers2 (firstName,lastName,registrationID,creditLimit,country)
                        values ('Anne', 'Clerk', 111, 5000.75, 'USA')");
    } onretry {
        a = a + " onRetry";
    } aborted {
        a = a + " trxAborted";
    }
    return a;
}

function testLocalTransactionSuccessWithFailed() returns (string, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    string a = "beforetx";
    string|error ret = trap testLocalTransactionSuccessWithFailedHelper(a, testDB);
    if (ret is string) {
        a = ret;
    } else {
        a =  a + "trapped";
    }
    a = a + " afterTrx";
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 222", ResultCount);
    int count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (a, count);
}

function testLocalTransactionSuccessWithFailedHelper(string status, h2:Client testDB) returns string {
    int i = 0;
    string a = status;
    transaction with retries = 4 {
        a = a + " inTrx";
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                    values ('James', 'Clerk', 222, 5000.75, 'USA')");
        if (i == 2) {
            _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                        values ('Anne', 'Clerk', 222, 5000.75, 'USA')");
        } else {
            _ = testDB->update("Insert into Customers2 (firstName,lastName,registrationID,creditLimit,country)
                                        values ('Anne', 'Clerk', 222, 5000.75, 'USA')");
        }
    } onretry {
        a = a + " onRetry";
        i = i + 1;
    } committed {
        a = a + " committed";
    }
    return a;
}

function testLocalTransactionFailedWithNextupdate() returns (int) {
    h2:Client testDB1;
    h2:Client testDB2;
    testDB1 = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    testDB2 = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int i = 0;
    var ret = trap testLocalTransactionFailedWithNextupdateHelper(testDB1);
    if (ret is error) {
        i = -1;
    }
    _ = testDB1->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                            values ('James', 'Clerk', 12343, 5000.75, 'USA')");
    _ = testDB1.stop();

    var dt = testDB2->select("Select COUNT(*) as countval from Customers where registrationID = 12343",
        ResultCount);
    i = getTableCountValColumn(dt);
    _ = testDB2.stop();
    return i;
}

function testLocalTransactionFailedWithNextupdateHelper(h2:Client testDB) {
    transaction {
        _ = testDB->update("Insert into Customers (firstNamess,lastName,registrationID,creditLimit,country)
                                    values ('James', 'Clerk', 1234, 5000.75, 'USA')");
    }
}

function testNestedTwoLevelTransactionSuccess() returns (int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = 0;
    int count;
    transaction {
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                values ('James', 'Clerk', 333, 5000.75, 'USA')");
        testNestedTwoLevelTransactionSuccessParticipant(testDB);
    } onretry {
        returnVal = -1;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 333", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal, count);
}

@transactions:Participant {}
function testNestedTwoLevelTransactionSuccessParticipant(h2:Client testDB) {
    _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                values ('James', 'Clerk', 333, 5000.75, 'USA')");
}

function testNestedThreeLevelTransactionSuccess() returns (int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = 0;
    int count;
    transaction {
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                values ('James', 'Clerk', 444, 5000.75, 'USA')");
        testNestedThreeLevelTransactionSuccessParticipant1(testDB);
    } onretry {
        returnVal = -1;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 444", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal, count);
}

@transactions:Participant {}
function testNestedThreeLevelTransactionSuccessParticipant1(h2:Client testDB) {
    _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                values ('James', 'Clerk', 444, 5000.75, 'USA')");
    testNestedThreeLevelTransactionSuccessParticipant2(testDB);
}

@transactions:Participant {}
function testNestedThreeLevelTransactionSuccessParticipant2(h2:Client testDB) {
    _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                values ('James', 'Clerk', 444, 5000.75, 'USA')");
}

function testNestedThreeLevelTransactionFailed() returns (int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int returnVal = 0;
    int count;
    var ret = trap testNestedThreeLevelTransactionFailedHelper(testDB);
    if (ret is int) {
        returnVal =  ret;
    }
    //check whether update action is performed
    var dt = testDB->select("Select COUNT(*) as countval from Customers where registrationID = 555", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return (returnVal, count);
}

function testNestedThreeLevelTransactionFailedHelper(h2:Client testDB) returns int {
    int returnVal = 0;
    transaction {
        _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                        values ('James', 'Clerk', 555, 5000.75, 'USA')");
        testNestedThreeLevelTransactionFailedHelperParticipant1(testDB);
    } onretry {
        returnVal = -1;
    }
    return returnVal;
}

@transactions:Participant {}
function testNestedThreeLevelTransactionFailedHelperParticipant1(h2:Client testDB) {
    _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                        values ('James', 'Clerk', 555, 5000.75, 'USA')");
    testNestedThreeLevelTransactionFailedHelperParticipant2(testDB);
}

@transactions:Participant {}
function testNestedThreeLevelTransactionFailedHelperParticipant2(h2:Client testDB) {
    _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                            values ('James', 'Clerk', 555, 5000.75, 'USA')");
    testNestedThreeLevelTransactionFailedHelperParticipant3(testDB);
}

@transactions:Participant {}
function testNestedThreeLevelTransactionFailedHelperParticipant3(h2:Client testDB) {
    _ = testDB->update("Insert into Customers (invalidColumn,lastName,registrationID,creditLimit,country)
                                            values ('James', 'Clerk', 555, 5000.75, 'USA')");
}

function testLocalTransactionWithSelectAndForeachIteration() returns (int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 5 }
    });

    _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                values ('James', 'Clerk', 900, 5000.75, 'USA')");
    _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                values ('James', 'Clerk', 900, 5000.75, 'USA')");

    int returnVal = 0;
    int count = -1;
    transaction {
        var dt1 = testDB->select("Select COUNT(*) as countval from Customers where
            registrationID = 900", ResultCount);
        if (dt1 is table<ResultCount>) {
            foreach var row in dt1 {
                count = row.COUNTVAL;
            }
        }
        var dt2 = testDB->select("Select COUNT(*) as countval from Customers where
            registrationID = 900", ResultCount);
        if (dt2 is table<ResultCount>) {
            foreach var row in dt2 {
                count = row.COUNTVAL;
            }
        }
    } onretry {
        returnVal = -1;
    }
    _ = testDB.stop();
    return (returnVal, count);
}

function testLocalTransactionWithSelectAndHasNextIteration() returns (int, int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 5 }
    });

    _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                values ('James', 'Clerk', 901, 5000.75, 'USA')");
    _ = testDB->update("Insert into Customers (firstName,lastName,registrationID,creditLimit,country)
                                values ('James', 'Clerk', 901, 5000.75, 'USA')");

    int returnVal = 0;
    int count = -1;
    transaction {
        var dt1 = testDB->select("Select COUNT(*) as countval from Customers where
            registrationID = 901", ResultCount);
        count = getTableCountValColumn(dt1);
        var dt2 = testDB->select("Select COUNT(*) as countval from Customers where
            registrationID = 901", ResultCount);
        count = getTableCountValColumn(dt2);
    } onretry {
        returnVal = -1;
    }
    _ = testDB.stop();
    return (returnVal, count);
}

function testCloseConnectionPool() returns (int) {
    h2:Client testDB = new({
        path: "./target/tempdb/",
        name: "TEST_SQL_CONNECTOR_TR",
        username: "SA",
        password: "",
        poolOptions: { maximumPoolSize: 1 }
    });

    int count;
    var dt = testDB->select("SELECT COUNT(*) as countVal FROM INFORMATION_SCHEMA.SESSIONS", ResultCount);
    count = getTableCountValColumn(dt);
    _ = testDB.stop();
    return count;
}

function getTableCountValColumn(table<ResultCount>|error result) returns int {
    int count = -1;
    if (result is table<ResultCount>) {
        while (result.hasNext()) {
            var rs = result.getNext();
            if (rs is ResultCount) {
                count = rs.COUNTVAL;
            }
        }
        return count;
    }
    return -1;
}
