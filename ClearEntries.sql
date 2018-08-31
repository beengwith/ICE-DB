-- Erase record and for reevaluation from finger print data

Declare @code int;
Declare @fromDate Datetime;
SET @code=9600497
SET @fromDate=CAST('2016-05-20' AS DATETIME)


Delete from FPEntries
--Select * from FPEntries
	where 
		L_UID = @code
		and
		C_Date >= REPLACE(CONVERT(CHAR(20), @fromDate, 102), '.', '') 

Delete from attendancedetails
--Select * from attendancedetails
	Where 
		EmployeeID = (Select Employeeid from Employee where EmployeeCode=CAST(@code AS VARCHAR))
		and
		TrackDate >= @fromDate
