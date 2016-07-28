select 
		Department 
		,count(EmployeeID) as Department_Strength
	 	from dbo.Employee, dbo.Department 
	 	where dbo.Employee.DepartmentID=dbo.Department.DepartmentID
	 	and dbo.Employee.EmployeeStatus=1
	 	and dbo.Department.Department != 'None'
		
GROUP by Department