DECLARE @begin_date datetime
DECLARE @end_date datetime
SET @begin_date = CAST('2015-05-28 00:00:00.000' as datetime)
SET @end_date   = CAST('2015-06-27 00:00:00.000' as datetime)

DECLARE @Holiday TABLE (
	HolidayDate datetime unique,
	Description text
);

DECLARE @date_counter datetime
SET @date_counter = @begin_date
WHILE @date_counter < @end_date
BEGIN
	IF DATENAME(dw, @date_counter) = 'Sunday' BEGIN
		INSERT INTO @Holiday VALUES (@date_counter, 'Sun')
	END
	SET @date_counter = DATEADD(d,1, @date_counter)
END

DECLARE @OptionalDay TABLE (
	OptionalDayDate datetime unique,
	Description text
);

SET @date_counter = @begin_date
WHILE @date_counter < @end_date
BEGIN
	IF DATENAME(dw, @date_counter) = 'Saturday' BEGIN
		INSERT INTO @OptionalDay VALUES (@date_counter, 'Sat (Optional)')
	END
	SET @date_counter = DATEADD(d,1, @date_counter)
END

select * from  @OptionalDay