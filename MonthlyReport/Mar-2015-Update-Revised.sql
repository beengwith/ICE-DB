DECLARE @begin_date datetime
DECLARE @end_date datetime
DECLARE @saturdays_optional bit
SET @begin_date = CAST('2018-01-01 00:00:00.000' as datetime)
SET @end_date   = CAST('2018-08-09 00:00:00.000' as datetime)
SET @saturdays_optional = 0

DECLARE @sandwiching bit
SET @sandwiching = 0

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
INSERT INTO @Holiday SELECT * FROM GetHolidays(@begin_date, @end_date, default);

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
SET @num_required_wdays = @accounted_days - @num_holidays -@num_optional_days

-- end calc

DECLARE @Sandwichable TABLE (
	EmployeeAttendanceId Int UNIQUE,
	EmployeeId Int,
	HolidayDate DateTime,
	HolidayStatus Text,
	NewStatus Text
)

IF (@Sandwiching=1) BEGIN
	INSERT INTO @Sandwichable
		SELECT * FROM GetSandwichables(@begin_date, @end_date, @saturdays_optional)
END

UPDATE EmployeeAttendance
set AttendanceStatus='Holiday', Description='Optional'
WHERE
    [AttendanceDate] >= @begin_date 
    AND
    [AttendanceDate] < @end_date 
    AND
    [AttendanceDate] IN (SELECT OptionalDayDate from @OptionalDay)
    AND
    [AttendanceDate] NOT IN (SELECT HolidayDate from @Sandwichable)
    AND
    [EmployeeID] in (SELECT EmployeeID FROM dbo.Employee WHERE EmployeeStatus=1)
    AND
    ([AttendanceStatus] in ('A', 'Holiday'))

UPDATE EmployeeAttendance
set AttendanceStatus='Holiday'
WHERE
	[AttendanceDate] >= @begin_date 
	AND
	[AttendanceDate] < @end_date 
	AND
	[AttendanceDate] IN (SELECT HolidayDate from @Holiday)
	AND
	[EmployeeID] in (SELECT EmployeeID FROM dbo.Employee WHERE EmployeeStatus=1)
	AND
	([AttendanceStatus] like 'A')

UPDATE EmployeeAttendance
SET TimeStatus='OverTime'
WHERE
	[AttendanceDate] >= @begin_date 
	AND
	[AttendanceDate] < @end_date 
	AND
	[AttendanceDate] IN (SELECT HolidayDate from @Holiday)
	AND
	[EmployeeID] in (SELECT EmployeeID FROM dbo.Employee WHERE EmployeeStatus=1)
	AND
	([AttendanceStatus] like '%Others%')
	AND
	([Description] like '%manual%')
	AND
	([TimeStatus] is NULL)
