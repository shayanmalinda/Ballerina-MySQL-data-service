import ballerina/time;
import ballerinax/mysql.driver as _;
import ballerinax/mysql;
import ballerina/sql;
import ballerina/http;

public type Employee record {|
    int employee_id?;
    string first_name;
    string last_name;
    string email;
    string phone;
    time:Date hire_date;
    int? manager_id;
    string job_title;
|};

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;

final mysql:Client dbClient = check new(
    host=HOST, user=USER, password=PASSWORD, port=PORT, database="Company"
);

service /employees on new http:Listener(8080) {

    isolated resource function post .(@http:Payload Employee emp) returns int|error? {
        return addEmployee(emp);
    }
    
    isolated resource function get [int id]() returns Employee|error? {
        return getEmployee(id);
    }
    
    isolated resource function get .() returns Employee[]|error? {
        return getAllEmployees();
    }
    
    isolated resource function put .(@http:Payload Employee emp) returns int|error? {
        return updateEmployee(emp);
    }
    
    isolated resource function delete [int id]() returns int|error? {
        return removeEmployee(id);       
    }

}

isolated function addEmployee(Employee emp) returns int|error {
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO Employees (employee_id, first_name, last_name, email, phone,
                               hire_date, manager_id, job_title)
        VALUES (${emp.employee_id}, ${emp.first_name}, ${emp.last_name},  
                ${emp.email}, ${emp.phone}, ${emp.hire_date}, ${emp.manager_id},
                ${emp.job_title})
    `);
    int|string? lastInsertId = result.lastInsertId;
    if lastInsertId is int {
        return lastInsertId;
    } else {
        return error("Unable to obtain last insert ID");
    }
}

isolated function getEmployee(int id) returns Employee|error {
    Employee employee = check dbClient->queryRow(
        `SELECT * FROM Employees WHERE employee_id = ${id}`
    );
    return employee;
}

isolated function getAllEmployees() returns Employee[]|error {
    Employee[] employees = [];
    stream<Employee, error?> resultStream = dbClient->query(
        `SELECT * FROM Employees`
    );
    check from Employee employee in resultStream
        do {
            employees.push(employee);
        };
    check resultStream.close();
    return employees;
}

isolated function updateEmployee(Employee emp) returns int|error {
    sql:ExecutionResult result = check dbClient->execute(`
        UPDATE Employees SET
            first_name = ${emp.first_name}, 
            last_name = ${emp.last_name},
            email = ${emp.email},
            phone = ${emp.phone},
            hire_date = ${emp.hire_date}, 
            manager_id = ${emp.manager_id},
            job_title = ${emp.job_title}
        WHERE employee_id = ${emp.employee_id}  
    `);
    int|string? lastInsertId = result.lastInsertId;
    if lastInsertId is int {
        return lastInsertId;
    } else {
        return error("Unable to obtain last insert ID");
    }
}

isolated function removeEmployee(int id) returns int|error {
    sql:ExecutionResult result = check dbClient->execute(`
        DELETE FROM Employees WHERE employee_id = ${id}
    `);
    int? affectedRowCount = result.affectedRowCount;
    if affectedRowCount is int {
        return affectedRowCount;
    } else {
        return error("Unable to obtain the affected row count");
    }
}
