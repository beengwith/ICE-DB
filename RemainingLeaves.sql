DECLARE @begin_date DateTime
DECLARE @end_date DateTime
SET @begin_date=CAST('2010-01-01 00:00:00.000' AS DATETIME)
SET @end_date=CAST('2017-01-01 00:00:00.000' AS DATETIME)

--SET @begin_date=dateadd(m, -3, dateadd(d, -datepart(d, dateadd(dd, 0, datediff(dd, 0, getDate())))+1, dateadd(dd, 0, datediff(dd, 0, getDate()))))
--select dateadd(m, -3, dateadd(d, -datepart(d, dateadd(dd, 0, datediff(dd, 0, getDate())))+1, dateadd(dd, 0, datediff(dd, 0, getDate()))))

set @end_date=CAST(Convert(varchar(50), GetDate(), 102) AS DATETIME)

select cast( '' + YEAR(GetDate()) + '0101'  AS DATETIME )


select CAST(CAST(YEAR(AnnualLeaves.AttendanceDate)+1 AS VARCHAR) + '.01.01' AS DATETIME)




Declare @total_per_year int
set @total_per_year = 14

SELECT
	CurrentEmployee.EmployeeID,
	CurrentEmployee.JoiningDate,
	YEAR(AnnualLeaves.AttendanceDate),
	count(AnnualLeaves.EmployeeID) as AL,
	datediff(joiningdate, convert(YEAR(AnnualLeaves.AttendanceDate) AS DATETIME )),
	CASE
		WHEN
			joiningDate < CAST(CAST(YEAR(AnnualLeaves.AttendanceDate)+1) AS VARCHAR) + '.01.01' AS DATETIME)
		THEN 1
		ELSE 0
		END
	
FROM
	(
		SELECT
			Employee.EmployeeID, EmployeeCode, EmployeeName,
			Designation, Department, JoiningDate
		FROM 
			Employee JOIN Department ON Employee.DepartmentID=Department.DepartmentID
			JOIN Designation ON Designation.DesignationID = Employee.DesignationID
			JOIN Company ON Company.CompanyID = Employee.CompanyID
			JOIN ShiftDetails ON Employee.EmployeeID = ShiftDetails.EmployeeID
		WHERE
			EmployeeStatus=1
	) AS CurrentEmployee
	JOIN
	(
		SELECT * 
		FROM 
			EmployeeAttendance
		WHERE
			AttendanceDate >= @begin_date
				AND AttendanceDate < @end_date
				AND AttendanceStatus = 'AL'
	) AS AnnualLeaves
	ON AnnualLeaves.EmployeeID = CurrentEmployee.EmployeeID
GROUP BY
	CurrentEmployee.EmployeeID,
	YEAR(AnnualLeaves.AttendanceDate),
	CurrentEmployee.JoiningDate
ORDER BY 
	CurrentEmployee.EmployeeID,
	YEAR(AnnualLeaves.AttendanceDate)

