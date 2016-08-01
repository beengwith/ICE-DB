DECLARE @begin_date datetime
DECLARE @end_date datetime
DECLARE @saturdays_optional bit
SET @begin_date = CAST('2016-02-26 00:00:00.000' as datetime)
SET @end_date   = CAST('2016-03-25 00:00:00.000' as datetime)
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
SET @num_required_wdays = @accounted_days - @num_holidays -@num_optional_days

-- end calc

--SELECT
--    @this_year AS this_year 
--    ,@this_month AS this_month
--    ,@prev_month AS prev_month
--    ,@begin_date AS begin_date
--    ,@end_date   AS end_date
--    ,@accounted_days AS accountable_days
--    ,@num_holidays AS holidays
--    ,@num_optional_days AS optional_days
--    ,@num_required_wdays AS num_required_working_days

select * from @holiday
--select * from @optionalday