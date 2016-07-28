SELECT [AttendanceDate]
		,EmployeeName
		,emp.EmployeeID
		,[AttendanceStatus]
		,att.[Description]
		,[EAID]
		,[TimeStatus]
		,[ApprovalStatus]
		,[ApprovedBy]
		,[HalfDay]
		,[ShortLeave]
		,[InHDay]
	FROM [dbo].[EmployeeAttendance] as att, Employee as emp
	WHERE att.EmployeeID = emp.EmployeeID
	and EmployeeName like '%adn%mal%'
	and AttendanceDate >= '2015-08-28'
	--and AttendanceDate < '2015-09-27'
	order by attendancedate