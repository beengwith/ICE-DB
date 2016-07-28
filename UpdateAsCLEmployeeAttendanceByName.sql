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
	and EmployeeName like 'sha%sab%'
	and AttendanceDate >= '2015-05-28'
	and AttendanceDate < '2015-06-27'
	order by attendancedate