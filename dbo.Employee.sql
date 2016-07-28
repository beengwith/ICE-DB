SELECT --emp.[EmployeeID]
		[EmployeeName]
		,[EmployeeCode]
		,[Designation]
		,[Department]
		,[FatherName]
		,[ContactNo] + ' ' + isnull([Mobile], '') as ContactNo
		,[DOB]
		,[EmployeeLogin]
		,[Address]
		,[CNIC]
	FROM [dbo].[Employee] as emp, dbo.Department as dep, dbo.Designation as des
	WHERE emp.DepartmentID = dep.DepartmentID
	AND	  emp.DesignationID = des.DesignationID
	AND   emp.EmployeeStatus=1
	ORDER BY Department, EmployeeName