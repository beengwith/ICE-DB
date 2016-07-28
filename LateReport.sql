SELECT 	
		EmployeeName
		,[TrackDate]
		,convert(varchar(8), min([InOutTime]), 108) as inTime
		,convert(varchar(8), max([InOutTime]), 108) as outTime
		,convert(varchar(8), max([InOutTime]) - min(InOutTime), 108) as WorkingHours
		
	FROM [dbo].[AttendanceDetails] as atd, Employee as emp
	Where atd.EmployeeID = emp.EmployeeID
	and 
--	(
	        EmployeeName like '%Asad%Jawaid%'
--		or	EmployeeName like '%Umair%Hameed%'
--		or	EmployeeName like 'Shariq mehmood'
--		or	EmployeeName like '%Waqas%javed%'
--	)
	and trackdate >= '2014-09-01'
	and trackdate <  '2014-10-28'
group by employeeName, trackdate
order by EmployeeName, trackdate
