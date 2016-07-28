SELECT 	
		[EmployeeName]
		--,[EmployeeCode]
		--,[CNIC]		
		,[Department]		
		,[Designation]
		,[JoiningDate]
		--,[DOB]		
		--,[FatherName]
		--,[Address]
		,[ContactNo]
		,[Mobile]
		
	FROM [dbo].[Employee] as emp,
			Department as dep, 
			Designation as des
			
	WHERE	emp.DesignationId = des.DesignationId
			and	emp.DepartmentId = dep.DepartmentId
			and emp.EmployeeId != 0 
			and EmployeeStatus = 1
			
	ORDER BY EmployeeStatus DESC,
			Department,
			EmployeeName

	