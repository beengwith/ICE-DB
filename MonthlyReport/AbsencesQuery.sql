DECLARE @begin_date datetime
DECLARE @end_date datetime

SET @begin_date = CAST('2016-06-26 00:00:00.000' as datetime)
SET @end_date   = CAST('2016-07-26 00:00:00.000' as datetime)

DECLARE @saturdays_optional bit
SET @saturdays_optional = 0


SELECT
	EmployeeName
	, EmployeeCode
	, Designation
	, Department
	, JoiningDate
	, AttendanceDate
	, AttendanceStatus
	, TimeStatus
	, ApprovalStatus
	, ApprovedBy
	
FROM
	(SELECT
		ActiveEmployee.EmployeeID
		,ActiveEmployee.EmployeeName
		,ActiveEmployee.EmployeeCode
		,Department.Department
		,Designation.Designation
		,ActiveEmployee.JoiningDate
	FROM
		(
			(
				SELECT
					EmployeeId
					,EmployeeName
					,EmployeeCode
					,JoiningDate
					,DepartmentID
					,DesignationID
					
				FROM
					Employee
				
				WHERE
					EmployeeStatus = 1
				) as ActiveEmployee
				JOIN
				Department
				ON ActiveEmployee.DepartmentID = Department.DepartmentID
			) 
		JOIN
		Designation
		ON Designation.DesignationID = ActiveEmployee.DesignationID
	) As EmployeeList
	JOIN
	( 
		SELECT 
			EmployeeId
			,AttendanceDate
			, AttendanceStatus
			, Description
			, TimeStatus
			, ApprovalStatus
			, ApprovedBy
		FROM 
			EmployeeAttendance
		WHERE
			[AttendanceDate] >= @begin_date 
			AND
			[AttendanceDate] < @end_date 
	) as DailyAttendance
	ON
	EmployeeList.EmployeeID = DailyAttendance.EmployeeID
	
WHERE 
	DailyAttendance.AttendanceStatus = 'A'

ORDER BY EmployeeList.EmployeeName
	