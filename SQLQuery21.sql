
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[GetDailyAttendanceData]
(
	@begin_date AS DATETIME,
	@end_date AS DATETIME
)
RETURNS TABLE
AS
RETURN (

--Declare @begin_date DATETIME
--Declare @end_date DATETIME
--set @begin_date = '2016-08-26'
--set @end_date = '2016-10-26'
--

SELECT	
	CurrentEmployee.EmployeeID,
	CurrentEmployee.EmployeeName,
	CurrentEmployee.EmployeeCode,
	CurrentEmployee.Department,
	CurrentEmployee.Designation,
	CurrentEmployee.JoiningDate,
	Days.Date, 
	Days.DayName,
	ISNULL(Days.Description, '') AS Holiday,
	(CASE WHEN
		MIN(ISNULL(inTime , CONVERT(DATETIME,
			'23:59:59'))) = CONVERT(DATETIME, '23:59:59')
		THEN NULL
		ELSE MIN(ISNULL(inTime , CONVERT(DATETIME, '23:59:59')))
		END	) as InTime,
	(CASE WHEN
		MAX(ISNULL(outTime, CONVERT(DATETIME, 0))) = CONVERT(DATETIME, 0)
		THEN NULL
		ELSE MAX(ISNULL(outTime, CONVERT(DATETIME, 0)))
		END	) as OutTime,
	MIN(CurrentEmployee.StartTime) as StartTime,
	MAX(CurrentEmployee.EndTime) as EndTime,
	AttendanceStatus,
	SUM(CASE
			WHEN ISNULL(diff, 0) < 0
			THEN 0 
			ELSE ISNULL(diff, 0)
			END) as WorkingHours,
	(CASE
		WHEN AttendanceStatus = 'C' 
			OR (AttendanceStatus = 'P' AND Days.Description IS NULL)
		THEN 480
		ELSE 0 END) as RequiredHours,
	(SUM((CASE
			WHEN ISNULL(diff, 0) < 0 
			THEN 0
			ELSE ISNULL(diff, 0)
			END)) - 
		(CASE
			WHEN 
				AttendanceStatus = 'C' 
				OR (AttendanceStatus = 'P' AND Days.Description IS NULL)
			THEN 480
			ELSE 0
			END)) as OverTime,
	(CASE
		WHEN 
			Days.Description is NULL
			AND MIN(ISNULL(inTime, 
				CONVERT(DATETIME, '23:59:59'))) > DATEADD(mi, 15, MIN(StartTime))
			AND MIN(ISNULL(inTime,
				CONVERT(DATETIME, '23:59:59'))) < dbo.HalfTime(MIN(StartTime), MAX(EndTime))
			AND AttendanceStatus = 'P'
		THEN 1
		ELSE 0
		END) AS Late,
	(CASE
		WHEN 
			Days.Description is NULL
			AND MIN(ISNULL(inTime,
				CONVERT(DATETIME, '23:59:59'))) >= dbo.HalfTime(MIN(StartTime), MAX(EndTime))
			AND AttendanceStatus = 'P'
		THEN 1
		ELSE 0
		END) AS HalfDay,
	(CASE
		WHEN
			Days.Description is NULL
			AND MAX(ISNULL(outTime,	CONVERT(DATETIME, 0))) < DATEADD(mi, -15, MAX(EndTime))
			AND	AttendanceStatus = 'P'
		THEN 1
		ELSE 0
		END) AS ShortLeave,
	ISNULL(Food, 0) as Food

FROM
	(
		SELECT
			Employee.EmployeeID, EmployeeCode, EmployeeName,
			Designation, Department, JoiningDate, CompanyName,
			dbo.GetTimeFromDateTime(TimeFrom) as StartTime, 
			dbo.GetTimeFromDateTime(TimeTo) as EndTime
		FROM 
			Employee JOIN Department ON Employee.DepartmentID=Department.DepartmentID
			JOIN Designation ON Designation.DesignationID = Employee.DesignationID
			JOIN Company ON Company.CompanyID = Employee.CompanyID
			JOIN ShiftDetails ON Employee.EmployeeID = ShiftDetails.EmployeeID
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
					-- :: getTimeFromDateTime = lambda @date: 
					--		CONVERT(DATETIME, CONVERT(VARCHAR(8), @date,108) )
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
	LEFT JOIN 
	(
		SELECT
			EmpID,
			CONVERT(DATETIME, CONVERT(VARCHAR(10), NgtDate, 102 ) ) as Date,
			1 as Food
		FROM
			Tbl_EmpNightSitting
	) as nyt
	ON nyt.EmpID = AttendanceData.EmployeeID AND nyt.Date=AttendanceData.AttendanceDate
WHERE
	Days.Date >= CurrentEmployee.JoiningDate
GROUP BY 
	CurrentEmployee.EmployeeID,
	CurrentEmployee.EmployeeName,
	CurrentEmployee.EmployeeCode,
	CurrentEmployee.Department,
	CurrentEmployee.Designation,
	CurrentEmployee.JoiningDate,
	Days.Date,
	Days.DayName,
	Days.Description,
	AttendanceData.AttendanceStatus,
	Food

)
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

