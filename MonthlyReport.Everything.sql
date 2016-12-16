DECLARE @begin_date DateTime
DECLARE @end_date DateTime
SET @begin_date=CAST('2016-09-01 00:00:00.000' AS DATETIME)
SET @end_date=CAST('2016-09-30 00:00:00.000' AS DATETIME)

SELECT	
	CurrentEmployee.EmployeeID,
	CurrentEmployee.EmployeeName,
	CurrentEmployee.EmployeeCode,
	CurrentEmployee.Department,
	CurrentEmployee.Designation,
	Days.Date, 
	Days.DayName,
	ISNULL(Days.Description, '') AS Holiday,
	MIN(ISNULL(inTime , CONVERT(DATETIME, '23:59:59'))) as InTime,
	MAX(ISNULL(outTime, CONVERT(DATETIME, 0         ))) as OutTime,
	AttendanceStatus,
	SUM(CASE WHEN ISNULL(diff, 0) < 0
		THEN 0 ELSE ISNULL(diff, 0) END) as WorkingHours,
	(CASE WHEN AttendanceStatus IN ('P', 'C')
		THEN 480 ELSE 0 END) as RequiredHours,
	(SUM(CASE WHEN ISNULL(diff, 0) < 0 
			THEN 0 ELSE ISNULL(diff, 0) END) -
		(CASE WHEN AttendanceStatus IN ('P', 'C')
			THEN 480 ELSE 0 END)) as OverTime,
	(CASE WHEN 
		Days.Description is not NULL AND 
		MIN(ISNULL(inTime , CONVERT(DATETIME, '23:59:59'))) > '10:05:00'
		AND AttendanceStatus = 'P'
		THEN 1 ELSE 0 END) as Late
FROM
	(
		SELECT
			Employee.EmployeeID, EmployeeCode, EmployeeName, Designation, Department, JoiningDate, CompanyName
		FROM 
			Employee JOIN Department ON Employee.DepartmentID=Department.DepartmentID
			JOIN Designation ON Designation.DesignationID = Employee.DesignationID
			JOIN Company ON Company.CompanyID = Employee.CompanyID
		WHERE
			EmployeeStatus=1
	) AS CurrentEmployee
	CROSS JOIN
	(
		SELECT * FROM
		GetDays(@begin_date, @end_date) as Days
		LEFT JOIN GetHolidays(@begin_date, @end_date) as Holidays
		ON Days.Date = Holidays.HolidayDate
	) As Days
	LEFT JOIN 
	(
		SELECT 
			ea.EmployeeID,
			ea.AttendanceDate,
			ad.inTime,
			ad.OutTime,
			ad.diff,
			ea.AttendanceStatus
		FROM 
			(
				SELECT
					adIn.EmployeeID,
					adIn.InOutID,
					adIn.TrackDate,
					-- :: getTimeFromDateTime = lambda @date: CONVERT(DATETIME, CONVERT(VARCHAR(8), @date,108) )
					dbo.GetTimeFromDateTime(adIn.InOutTime) as InTime,
					dbo.GetTimeFromDateTime(adOut.InOutTime) as OutTime,
					DATEDIFF(MINUTE, dbo.GetTimeFromDateTime(adIn.InOutTime), 
						dbo.GetTimeFromDateTime(
							ISNULL(adOut.InOutTime, adIn.InOutTime))) as diff
				FROM
					(
						SELECT *
						FROM AttendanceDetails
						WHERE
							TrackDate >= @begin_date
							AND TrackDate < @end_date
							AND InOutStatus='In'
					) as adIn 
					LEFT JOIN
					(
						SELECT *
						FROM AttendanceDetails
						WHERE
							TrackDate >= @begin_date
							AND TrackDate < @end_date
							AND InOutStatus='Out'
					) as adOut 
					ON adIn.InOutID = adOut.InOutID
						AND adIn.EmployeeID = adOut.EmployeeID
			) AS ad
			RIGHT JOIN
			(
				SELECT * 
				FROM 
					EmployeeAttendance
				WHERE
					AttendanceDate >= @begin_date
					AND AttendanceDate < @end_date
			) as ea
			ON ad.TrackDate = ea.AttendanceDate AND ad.EmployeeID = ea.EmployeeID
			WHERE ea.EmployeeID is not NULL
	) AS AttendanceData
	ON CurrentEmployee.EmployeeID = AttendanceData.EmployeeID AND Days.Date=AttendanceData.AttendanceDate
GROUP BY 
	CurrentEmployee.EmployeeID,
	CurrentEmployee.EmployeeName,
	CurrentEmployee.EmployeeCode,
	CurrentEmployee.Department,
	CurrentEmployee.Designation,
	Days.Date,
	Days.DayName,
	Days.Description,
	AttendanceData.AttendanceStatus
