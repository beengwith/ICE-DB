DECLARE @begin_date datetime
DECLARE @end_date datetime

SET @begin_date = CAST('2015-03-01 00:00:00.000' as datetime)
SET @end_date   = CAST('2015-03-09 00:00:00.000' as datetime)


SELECT
	Department
	,count(att.EmployeeID) as DepartmentStrength 
FROM
	(SELECT 
		EmployeeID
	FROM EmployeeAttendance
	WHERE
		[AttendanceDate] >= @begin_date 
		AND
		[AttendanceDate] < @end_date
		AND 
		[AttendanceStatus] = 'P'
	group by [EmployeeID]) as att

	INNER JOIN

	( select EmployeeID
			,Department 
	 	from dbo.Employee, dbo.Department 
	 	where dbo.Employee.DepartmentID=dbo.Department.DepartmentID
	) as empdep
		
	ON att.EmployeeID = empdep.EmployeeID
		
GROUP by Department

