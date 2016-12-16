DECLARE @begin_date datetime
DECLARE @end_date datetime
DECLARE @saturdays_optional bit
SET @begin_date = CAST('2016-07-26 00:00:00.000' as datetime)
SET @end_date   = CAST('2016-08-26 00:00:00.000' as datetime)
SET @saturdays_optional = 0

-- declare local vars
DECLARE @this_year int
DECLARE @this_month int
DECLARE @prev_month int
DECLARE @accounted_days int
DECLARE @num_required_wdays int
DECLARE @num_holidays int
DECLARE @num_optional_days int

DECLARE @Holiday TABLE (
	HolidayDate datetime unique,
	Description text
);

DECLARE @OptionalDay TABLE (
	OptionalDayDate datetime unique,
	Description text
);

-- Adding Holidays to a list
INSERT INTO @Holiday SELECT * FROM GetHolidays(@begin_date, @end_date);

-- IF Saturdays are optional add them to a list too
IF (@saturdays_optional=1) BEGIN
	INSERT INTO @OptionalDay SELECT * FROM GetSaturdays(@begin_date, @end_date);
END

-- Precalculate some stuff
SET @this_year  = YEAR(@end_date)
SET @this_month = MONTH(@end_date)
SET @prev_month = MONTH(@begin_date)
SET @accounted_days = DATEDIFF(d, @begin_date, @end_date)
SET @num_holidays = (SELECT COUNT(HolidayDate) FROM @Holiday)
SET @num_optional_days = (SELECT COUNT(OptionalDayDate) FROM @OptionalDay)
SET @num_required_wdays = @accounted_days - @num_holidays - @num_optional_days

-- end calc
DECLARE @aggregate TABLE (
	EmployeeID int,
	AttendanceDate datetime,
	AccountableDays int,
	AttendanceStatus text,
	Description text	
);

INSERT INTO @aggregate (
	EmployeeID,
	AttendanceDate,
	AccountableDays,
	AttendanceStatus,
	Description
)
(SELECT
	emp.EmployeeID
	,att.AttendanceDate
	,(CASE WHEN emp.JoiningDate > @begin_date THEN DATEDIFF(d, emp.JoiningDate,@end_date) ELSE @accounted_days END) AS AccountableDays
	,att.AttendanceStatus
	,att.Description 

FROM 
	(	-- get daily attendance
		SELECT *
		FROM EmployeeAttendance
		WHERE
			[AttendanceDate] >= @begin_date 
			AND
			[AttendanceDate] < @end_date 
	) AS att
	INNER JOIN (SELECT * FROM dbo.Employee WHERE EmployeeStatus=1) AS emp 
			ON emp.EmployeeID=att.EmployeeID
);

--select * from @aggregate where employeeid = 393

SELECT 
	--EmployeeID,
	EmployeeCode 
	,EmployeeName
	,Department
	,Designation
	,JoiningDate
	,AccountableDays
	,(	wday_Presents + hday_Presents + manual_wday_Presents + manual_hday_Presents + optional_Presents + manual_optional_Presents +
		CompensationsAvailed + CasualLeavesAvailed + SickLeavesAvailed + AnnualLeavesAvailed + MarriageLeavesAvailed + HolidaysAvailed + GeneralLeavesAvailed 
		) as EarnedDays
	,Absents as UnfiledAbsences
	,(CompensationsAvailed + CasualLeavesAvailed + SickLeavesAvailed + AnnualLeavesAvailed + MarriageLeavesAvailed + GeneralLeavesAvailed ) as ApprovedLeaves
	,(hday_Presents + manual_hday_Presents) as ExtraDays
	,(Others + Absents +
		wday_Presents + hday_Presents + manual_hday_Presents + manual_wday_Presents + optional_Presents + manual_optional_Presents + 
		CompensationsAvailed + CasualLeavesAvailed + SickLeavesAvailed + AnnualLeavesAvailed + MarriageLeavesAvailed + HolidaysAvailed + GeneralLeavesAvailed
		) as TotalRecordedDays
FROM
(SELECT
	emp.EmployeeId as employeeID,
	emp.EmployeeCode as EmployeeCode,
	emp.EmployeeName as EmployeeName,
	dep.Department as Department, 
	des.Designation as Designation,
	emp.JoiningDate as JoiningDate,
	(CASE WHEN emp.JoiningDate > @begin_date THEN DATEDIFF(d, emp.JoiningDate,@end_date) ELSE @accounted_days END) AS AccountableDays,
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('P' as text)
		AND agg.AttendanceDate NOT IN (SELECT HolidayDate from @Holiday)
		AND agg.AttendanceDate NOT IN (SELECT OptionalDayDate from @OptionalDay) ) as wday_Presents,
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('Others' as text)
		AND agg.Description like '%manual%'
		AND agg.AttendanceDate NOT IN (SELECT HolidayDate from @Holiday)
		AND agg.AttendanceDate NOT IN (SELECT OptionalDayDate from @OptionalDay)) as manual_wday_Presents,
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('P' as text)
		AND agg.AttendanceDate IN (SELECT HolidayDate from @Holiday)) as hday_Presents,
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('Others' as text)
		AND (agg.Description like '%manual%' OR agg.Description Like '%Compensate%')
		AND agg.AttendanceDate IN (SELECT HolidayDate from @Holiday)) as manual_hday_Presents,
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('P' as text)
		AND agg.AttendanceDate IN (SELECT OptionalDayDate from @OptionalDay)) as optional_Presents,
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('Others' as text)
		AND agg.Description like '%manual%'
		AND agg.AttendanceDate IN (SELECT OptionalDayDate from @OptionalDay)) as manual_optional_Presents,
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('Others' as text)
		AND agg.Description NOT LIKE '%manual%'
		AND agg.AttendanceDate NOT IN (SELECT HolidayDate from @Holiday)) as Others,
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('A' as text)) as Absents, --assumes all holidays and optional days have been corrected for
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('C' as text)) as CompensationsAvailed,
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('CL' as text)) as CasualLeavesAvailed,	
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('SL' as text)) as SickLeavesAvailed,	
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('AL' as text)) as AnnualLeavesAvailed,
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('Marriage Leave' as text)) as MarriageLeavesAvailed,
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('Holiday' as text)) as HolidaysAvailed,
	(SELECT COUNT(EmployeeID) FROM @aggregate as agg WHERE agg.EmployeeID=emp.EmployeeID AND agg.AttendanceStatus LIKE CAST('General Leave' as text)) as GeneralLeavesAvailed
	
FROM
	Employee as emp
	INNER JOIN Department as dep
		ON dep.DepartmentID = emp.DepartmentID
	INNER JOIN Designation as des
		ON des.DesignationID = emp.DesignationID
WHERE
	emp.EmployeeStatus=1
	AND emp.EmployeeCode NOT LIKE 'None'
	
) AS agg
--WHERE (Others + wday_Presents + hday_Presents + manual_wday_Presents + CompensationsAvailed + CasualLeavesAvailed + SickLeavesAvailed + AnnualLeavesAvailed + MarriageLeavesAvailed + HolidaysAvailed ) < AccountableDays
order by department, EmployeeName
--ORDER BY EarnedDays
--ORDER BY TotalRecordedDays, UnfiledAbsences desc