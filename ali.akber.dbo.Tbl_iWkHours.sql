SELECT 
		EmpId
		,sum(daywkhrs - 3600*9) / 3600 / 9
		--,compensationinfo
	FROM [dbo].[Tbl_iWkHours]
	Where EmpID = 370
		and compensationinfo is NULL
		and Date >= '2015-01-01'
	group by
		empid



SELECT 
		EmpId
		,sum(daywkhrs - 3600*9) / 3600 / 9
		--,compensationinfo
	FROM [dbo].[Tbl_iWkHours]
	Where EmpID = 370
		and compensationinfo is NULL
		and Date >= '2015-01-01'
	group by
		empid


