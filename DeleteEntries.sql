USE TestDB;

Declare @code int;
Declare @fromDate DateTime;
SET @fromDate=CAST('2018-01-01' AS DATETIME)

Delete from FPEntries
Where
    C_Date >= REPLACE(CONVERT(CHAR(20), @fromDate, 102), '.', '') 
    And L_UID in (
        Select EmployeeCode
        From Employee
        Where EmployeeStatus=1
    )

Delete from attendancedetails
Where
    TrackDate >= @fromDate
    And EmployeeID in (
        Select EmployeeId
        From Employee
        Where EmployeeStatus=1
    )

Delete from employeeAttendance
Where AttendanceDate >= @fromDate
    And EmployeeID in (
        Select EmployeeId
        From Employee
        Where EmployeeStatus=1
    )
    And AttendanceStatus in ('P', 'A')

Go
