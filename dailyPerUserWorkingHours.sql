--declare @startdate datetime-
--declare @enddat


SELECT [Tbl_WKID]
		,employeename
		,department
		,[Date]
 	    ,[HolidayDetail]
 	    ,[DayWkHrs]
		,[TWkHrs]

	FROM ([dbo].[Tbl_iWkHours] as wk 
			INNER JOIN
			( 
				Employee INNER JOIN Department 
				ON Employee.DepartmentID = department.departmentID
			) 
			ON Employee.employeeid = wk.empid)
	Where 
		employee.employeestatus=1
		and department.department in ( 'Animations', 'Lighting', 'Modeling', 'Rigging' )
		and wk.date between '2015-07-10' and '2015-07-12'
	order by 
		department, employeename
	
