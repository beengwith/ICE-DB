DECLARE @begin_date datetime
DECLARE @end_date datetime
DECLARE @saturdays_optional bit
SET @begin_date = CAST('2015-01-01 00:00:00.000' as datetime)
SET @end_date   = CAST('2015-10-28 00:00:00.000' as datetime)
SET @saturdays_optional = 0

DECLARE @daySeconds int
SET @daySeconds = 8 * 3600

DECLARE @ActiveEmployee TABLE (
	EmployeeId Int,
	EmployeeCode Text,
	EmployeeName Text,
	Designation Text,
	Department Text
);

INSERT INTO @ActiveEmployee
SELECT 
	emp.EmployeeID,
	emp.EmployeeCode,
	emp.EmployeeName,
	des.Designation,
	dep.Department
FROM
	Employee AS emp
	INNER JOIN Department AS dep
		ON dep.DepartmentID = emp.DepartmentID
	INNER JOIN Designation AS des
		ON des.DesignationID = emp.DesignationID
WHERE
	emp.EmployeeStatus=1
	AND emp.EmployeeCode NOT LIKE 'None'

DECLARE @Holiday TABLE (
	HolidayDate datetime unique,
	Description text
);
-- Adding Holidays to a list
INSERT INTO @Holiday SELECT * FROM GetHolidays(@begin_date, @end_date);


DECLARE @ExtraContribution TABLE (
	EmployeeID Int unique,
	ExtraTime Int
);


INSERT INTO @ExtraContribution

SELECT 
	eb.EmployeeID,
	sum(extra_contribution) as ExtraTime

FROM (

SELECT 
	EmployeeID,
	AttendanceDate,
	( CASE WHEN DayWkHrs is NULL THEN 0 ELSE DayWkHrs END) AS Seconds,
	AttendanceStatus,
	Description,
	( CASE 
	  	WHEN AttendanceDate in (Select HolidayDate From @Holiday) THEN 1
	  	ELSE 0
	  END ) as hDay,
	( CASE
		WHEN (AttendanceStatus = 'P' OR (AttendanceStatus='manual' AND (Description LIKE '%manual%')) AND AttendanceDate NOT IN (Select HolidayDate From @Holiday)) THEN 
			( CASE WHEN DayWkHrs IS NULL THEN 0 ELSE DayWkHrs END ) - @daySeconds
		WHEN ((AttendanceStatus = 'P' OR (AttendanceStatus='manual' AND (Description LIKE '%manual%' or Description like '%compensate%'))) AND AttendanceDate IN (Select HolidayDate From @Holiday)) THEN 
			( CASE WHEN DayWkHrs IS NULL THEN 0 ELSE DayWkHrs END )
		WHEN AttendanceStatus = 'C' THEN
			-@daySeconds
		ELSE
			0
	  END
	) as extra_contribution
	
FROM
	( Select *
	  FROM 
	  		EmployeeAttendance
	  WHERE 
	  		AttendanceDate BETWEEN @begin_date AND @end_date
	  		AND EmployeeID IN (SELECT EmployeeID From @ActiveEmployee)
	  		AND EmployeeID=186
	  		--AND AttendanceStatus = 'others'
	) AS att
	LEFT JOIN
	Tbl_iwkHours AS wk
	ON wk.Date = att.AttendanceDate	AND wk.EmpID = att.EmployeeID

) AS eb
GROUP BY eb.EmployeeID


SELECT 
	e.EmployeeId,
	EmployeeCode,
	EmployeeName,
	Designation,
	Department,
	CAST(ExtraTime/@daySeconds AS Int) as ExtraDays
FROM
	@ActiveEmployee as e JOIN @ExtraContribution AS c ON e.EmployeeID = c.EmployeeID
	
	