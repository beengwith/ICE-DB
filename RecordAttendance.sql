Set ANSI_NULLS ON;
Set QUOTED_IDENTIFIER ON;
GO

Drop Function [dbo].[GetTrackDate]
Go
Create Function [dbo].[GetTrackDate] (@a_time DateTime, @delay_hrs int=8)
Returns DateTime
As Begin
    Declare @r_date DateTime;
    Set @r_date = dateadd(hh, -@delay_hrs, @a_time);
    Return dbo.GetDateFromDateTime(@r_date)
End

GO

Drop Function [dbo].[GetWorkingDayStart]
Go
Create Function [dbo].[GetWorkingDayStart] (
    @a_time DateTime, @delay_hrs int=8
) Returns DateTime As Begin
    Declare @end_time DateTime;
    Set @end_time = dateadd(hh, @delay_hrs,
        dbo.GetTrackDate(@a_time, @delay_hrs));
    Return @end_time;
End

GO

Drop Function [dbo].[GetWorkingDayEnd]
Go
Create Function [dbo].[GetWorkingDayEnd] (
    @a_time DateTime, @delay_hrs int=8
) Returns DateTime As Begin
    Declare @end_time DateTime;
    Set @end_time = dateadd(hh, 24 + @delay_hrs,
        dbo.GetTrackDate(@a_time, @delay_hrs))
    Set @end_time = dateadd(mi, -1, @end_time)
    Return @end_time
End

GO

Drop Function [dbo].[IsSameWorkingDay]
Go
Create Function [dbo].[IsSameWorkingDay] (
    @time1 DateTime, @time2 DateTime, @delay_hrs int=8
) Returns Int 
AS Begin
    Return (
        CASE WHEN DateDiff(dd, dbo.GetTrackDate(@time1, @delay_hrs),
            dbo.GetTrackDate(@time2, @delay_hrs)) = 0
        THEN 1 ELSE 0 END
    )
End

GO

Drop Function [dbo].[IsEarlierWorkingDay]
Go
Create Function [dbo].[IsEarlierWorkingDay] (
    @time1 DateTime, @time2 DateTime, @delay_hrs int=8
) Returns Int 
As Begin
    Return (
        CASE WHEN DateDiff(
            dd, dbo.GetTrackDate(@time1, @delay_hrs),
            dbo.GetTrackDate(@time2, @delay_hrs)) > 0
        THEN 1 ELSE 0 END
    )
End
GO

Drop Function [dbo].[GetDayStatus]
Go
Create Function [dbo].[GetDayStatus] (
    @date DateTime, @sat_optional Bit = 1
) Returns Varchar(10)
As Begin
    Declare @day_status Varchar(10);
    Set @day_status = ''

    If @sat_optional = 1 And DateName(dw, @date) = 'Saturday' Begin
        Set @day_status = 'Optional';
    End

    Select @day_status = 'Weekend'
    From Weekend
    Where Weekend=DateName(dw, @date)

    Select @day_status = Description
    From DayDetails
    Where dbo.GetDateFromDateTime(@date) = TodayDate

    Return @day_status
End

GO

Drop Function [dbo].[GenerateInOutID]
Go
Create Function [dbo].[GenerateInOutID] ( @eid varchar(10)) Returns Int
As Begin
    Declare @InOutId int;

    Select @InOutID=IsNull(Max(InOutID),0) + 1
    from AttendanceDetails
    where EmployeeID = @eid

    Return @InOutId;
End

GO

Drop Function [dbo].[IsLaterWorkingDay]
Go
Create Function [dbo].[IsLaterWorkingDay] (
    @time1 DateTime, @time2 DateTime, @delay_hrs int=8
) Returns Int 
AS Begin
    Return (CASE WHEN DateDiff(dd, dbo.GetTrackDate(@time1, @delay_hrs),
            dbo.GetTrackDate(@time2, @delay_hrs)) < 0 THEN 1 ELSE 0 END)
End

GO

Drop Procedure [dbo].[CreateOrUpdateDailyAttendance]
Go
Create Procedure [dbo].[CreateOrUpdateDailyAttendance] (
    @eid Int, @trackDate DateTime, @attendanceStatus Varchar(50),
    @timeStatus Varchar(50) = NULL, @description Varchar(100) = NULL
) As Begin
    -- Check if an entry already exists
    Declare @prevAttStatus Varchar(50), @prevTimeStatus Varchar(50);
    Declare @prevDescription Varchar(100);
    Select
        @prevAttStatus=AttendanceStatus, @prevTimeStatus=TimeStatus,
        @prevDescription = description
    From EmployeeAttendance As Ea
        Inner Join Employee as Emp on Ea.EmployeeId = Emp.EmployeeId
    Where Emp.EmployeeId = @eid And AttendanceDate = @trackDate

    If @prevAttStatus is NULL Begin
        -- Insert if there is no existing entry
        Insert Into EmployeeAttendance(AttendanceDate, EmployeeID,
            AttendanceStatus, TimeStatus, description)
        Values(@trackDate, @eid, @attendanceStatus, @timeStatus, @description)
    End
    Else Begin
        -- Update if entry already exists
        If @prevAttStatus = 'P' or @timeStatus is NULL Begin
            Set @timeStatus = @prevTimeStatus;
        End

        If @attendanceStatus is NULL Or @prevAttStatus != 'A' Or
            @prevAttStatus != 'P' Begin
            Set @attendanceStatus = @prevAttStatus
        End

        If @description is NULL Begin
            Set @description = @prevDescription
        End

        Update EmployeeAttendance
        Set
            AttendanceStatus=@attendanceStatus, TimeStatus=@timeStatus,
            description=@description
        Where EmployeeID = @eid AND AttendanceDate = @TrackDate;
    End
End

GO

Drop Procedure [dbo].[RecordAttendance]
Go
Create Procedure [dbo].[RecordAttendance] (
    @ecode Int, @trackDate DateTime, @inOutTime DateTime
) As Begin

    if @ecode = 0 Begin
        Print 'Employeecode is Zero!';
        Return;
    End

    -- Get Shift Details for the user
    Declare @timeFrom DateTime, @timeTo DateTime, @eid Int;
    Select @eid=EmployeeID From Employee Where EmployeeCode = Cast(@ecode as varchar)

    if @eid is NULL Begin
        Print 'Employee Code is not active';
        Return;
    End

    Select @timeFrom=timeFrom, @timeTo=timeTo
    From ShiftDetails
    Where SDID = (Select Max(SDID) From ShiftDetails Where EmployeeID = @eid)


    -- Get Late Time
    Declare @late_time DateTime;
    Set @late_time = DateAdd(mi, 30, dbo.makeDateTime(
        Convert(varchar(50), @trackDate, 102),
        Convert(varchar(50), @timeFrom, 108))

    -- Get Last Transaction
    Declare @lastInOutID Int, @lastTrackDate DateTime;
    Declare @lastInOutTime DateTime, @LastInOutStatus Varchar(10);

    Select
        @lastInOutId=InOutId, @lastTrackDate=TrackDate,
        @lastInOutTime=InOutTime, @lastInOutStatus=InOutStatus
    From AttendanceDetails
    Where
        ADID = (
            Select IsNull(Max(ADID), 0)
            From AttendanceDetails
            Where EmployeeID = @eid
        )

    -- Check if today is a holiday or an Optional Day
    Declare @day_status varchar(10);
    Set @day_status = dbo.GetDayStatus(@trackDate, default)

    -- Is Employee late?
    Declare @timeStatus Varchar(50);
    Set @timeStatus = (
        Case
            When @day_status != '' And @day_status != 'Optional' Then 'OverTime'
            When @day_status = '' And @inOutTime > @late_time Then 'Late'
            Else 'InTime'
        End)

    If @lastInOutID Is NULL Begin

        Exec CreateOrUpdateDailyAttendance @eid, @trackDate, 'P', @timeStatus;

        Insert Into
        AttendanceDetails(InOutID, EmployeeID,
                TrackDate, InOutTime, InOutStatus)
        Values(dbo.GenerateInOutID(@eid), @eid,
                @TrackDate, @InOutTime, 'In');

    End
    Else Begin
        -- If there is also an existing entry
        Declare @dateCounter Datetime;
        If @lastInOutStatus = 'In' Begin
            -- If the previous entry is in
            If @lastTrackDate < @trackDate Begin
                Set @dateCounter = DateAdd(dd, 1, @lastTrackDate)
                While @dateCounter < @trackDate Begin

                    Exec CreateOrUpdateDailyAttendance @eid, @dateCounter,
                            'P', '', default;
                    Set @dateCounter = DateAdd(dd, 1, @dateCounter);

                End
                Exec CreateOrUpdateDailyAttendance @eid, @dateCounter, 'P',
                        @timeStatus, default;
            End
            -- Detail Entry
            Insert INTO
            AttendanceDetails(InOutID, EmployeeID, TrackDate, InOutTime,
                InOutStatus)
            Values(@lastInOutID, @eid, @TrackDate, @InOutTime, 'Out');
        End
        Else Begin
            -- If the previous entry is out
            If @lastTrackDate < @trackDate Begin
                Set @dateCounter = DateAdd(dd, 1, @lastTrackDate);
                While @dateCounter < @trackDate Begin
                    Declare @attendance_status Varchar(50);
                    Set @attendance_status = Case When @day_status = '' Then 'A' Else 'Holiday' End;
                    Exec CreateOrUpdateDailyAttendance @eid, @dateCounter,
                        @attendance_status, '', default;
                    Set @dateCounter = DateAdd(dd, 1, @dateCounter);
                End
                Exec CreateOrUpdateDailyAttendance @eid, @dateCounter, 'P',
                        @timeStatus, default;
            End
            -- Detail Entry
            Insert INTO
            AttendanceDetails(InOutID, EmployeeID, TrackDate, InOutTime,
                InOutStatus)
            Values(dbo.GenerateInOutID(@eid), @eid, @TrackDate, @InOutTime, 'In');
        End
    End


End

GO

Drop Procedure [dbo].[RecordFingerPrintEntry];
Go
Create Procedure [dbo].[RecordFingerPrintEntry] (
    @ecode Int, @tid Int, @date CHAR(8), @time CHAR(6)
) As Begin

    DECLARE @lastDate DateTime, @lastInOutTime DateTime;
    DECLARE @lastStatus varchar(8);
    DECLARE @inOutTime DateTime, @newInOutTime DateTime;
    DECLARE @trackDate DateTime, @status varchar(5);

    -- This Entry
    Set @inOutTime = dbo.makeDateTime(@date, @time);
    Set @trackDate = dbo.GetTrackDate(@inoutTime, default);
    Set @status = (
        CASE
            WHEN @tid = 1 THEN 'In'
            WHEN @tid = 2 THEN 'Out'
            WHEN @tid = 3 THEN 'In'
            WHEN @tid = 4 THEN 'Out'
        END)

    -- Getting the last entry for this user
    Select @lastDate=TrackDate, @lastInOutTime=InOutTime, @lastStatus=InOutStatus
    From AttendanceDetails
    Where ADID = (
            Select IsNull(Max(ADID),0)
            from AttendanceDetails
            where EmployeeID = (
                Select EmployeeID
                From Employee
                Where EmployeeCode=Cast(@ecode as varchar)
        ));


    If @status = 'Out' Begin -- 'Out' Now
        If @lastStatus = 'In' Begin
            -- If "Out" now and last Entry is "In" on sameday
            If dbo.isSameWorkingDay(@inOutTime, @lastInOutTime, default) = 1 Begin
                -- Then mark attendance normally
                Exec RecordAttendance @ecode, @trackDate, @inOutTime;
            End
            -- If "Out" now and last Entry is "In" on some earlierday
            If dbo.IsEarlierWorkingDay(@lastInOutTime, @inOutTime, default) = 1 Begin
                -- Then "Out" at the end of the last working day
                Set @newInOutTime = dbo.GetWorkingDayEnd(@lastInOutTime, default)
                Exec RecordAttendance @ecode, @lastDate, @newInOutTime;
                -- Then "In" start of day today and "Out Now"
                Set @newInOutTime = dbo.GetWorkingDayStart(@inOutTime, default);
                Exec RecordAttendance @ecode, @trackDate, @newInOutTime 
                Exec RecordAttendance @ecode, @trackDate, @inOutTime 
            End
        End
        Else Begin -- @lastStatus = 'Out'
            -- If now 'Out' on same day
            If dbo.isSameWorkingDay(@trackDate, @lastDate, default) = 1 Begin
                -- mark In and Then mark Out
                Set @newInOutTime = DateAdd(hh, 1, @lastInOutTime);
                If @newInOutTime > @inOutTime Begin
                    Set @newInOutTime = DateAdd(mi, -1, @inOutTime);
                End
                Exec RecordAttendance @ecode, @trackDate, @newInOutTime;
                Exec RecordAttendance @ecode, @trackDate, @inOutTime;
            End
            -- If now 'Out' on some earlier day
            Else Begin
                -- mark In late today and Then mark Out now
                Set @newInOutTime = DateAdd(hh, 14, @trackDate);
                If @newInOutTime > @InOutTime Begin
                    Set @newInOutTime = @InOutTime;
                End
                Exec RecordAttendance @ecode, @trackDate, @newInOutTime;
                Exec RecordAttendance @ecode, @trackDate, @inOutTime;
            End
        End
    End
    Else Begin -- "In"
        If @lastStatus = 'Out' Begin
            -- if Now 'Out' and last 'In' Just mark!
            Exec RecordAttendance @ecode, @trackdate, @inoutTime;
        End
        Else Begin
            -- do something
            -- If Now 'In' and last 'In' On Earlier Day
            if dbo.IsEarlierWorkingDay(@lastDate, @trackDate, default) = 1 Begin
                -- Mark Out on Earlier Day and Mark In Today 
                Set @newInOutTime = DateAdd(hh, 4, @lastInOutTime);
                if dbo.isLaterWorkingDay(@newInOutTime, @inOutTime, default) = 1
                Begin
                    Set @newInOutTime = dbo.GetWorkingDayEnd(@newInOutTime,
                        default);
                End
                EXEC RecordAttendance @ecode, @lastDate, @newInOutTime;
                EXEC RecordAttendance @ecode, @trackDate, @inOutTime;
            End
            ELSE Begin
                -- If Both "In"s are today
                If dbo.isSameWorkingDay(@inoutTime, @lastInOutTime, default) = 1
                Begin
                    -- Mark "Out" now and Mark "In"
                    Set @newInOutTime = dateadd(mi, -1, @inOutTime);
                    EXEC RecordAttendance @ecode, @trackDate, @newInOutTime;
                    EXEC RecordAttendance @ecode, @trackDate, @inOutTime;
                End
            End
        End
    End

    End

GO

Drop Procedure [dbo].[RecordManualEntry]
Go
Create Procedure [dbo].[RecordManualEntry] (
    @emid Int, @EmployeeCode Int, @trackDate DateTime,
    @inTime DateTime, @outTime DateTime
) Begin
    Declare @empId;

    -- Get Employee ID
    Select @empId = employeeId From Employee Where EmployeeCode = @employeeCode

    if @empId is NULL Begin
        Print 'No EmployeeId found for the code';
        Return;
    End

    Set @trackDate = dbo.GetDateFromDateTime(@trackDate);

    -- Get inTime and outTime
    Declare @timeFrom DateTime, @timeTo DateTime, @eid Int;

    Select @timeFrom=timeFrom, @timeTo=timeTo
    From ShiftDetails
    Where SDID = (Select Max(SDID) From ShiftDetails Where EmployeeID = @eid)

    Declare @late_time DateTime;
    Set @late_time = DateAdd(mi, 30, dbo.makeDateTime(
        Convert(varchar(50), @trackDate, 102),
        Convert(varchar(50), @timeFrom, 108))

    -- Get the already
    Declare @eaid int, @attendanceStatus Varchar(50);
    Declare @description Varchar(100), @timeStatus Varchar(50);

    Select @eaid = eaid, @description = description
    From EmployeeAttendance
    Where EmployeeID = @empId And AttendanceDate = @trackDate

    -- modifications
    If (lateTime >= inTime) Set @timeStatus = 'InTime';
    If @eaid is NULL Set @description = 'Manual Attendance';
    Set @attendanceStatus = 'P'

    Exec dbo.CreateOrUpdateDailyAttendance @empId, @trackDate, @attendanceStatus, @timeStatus, @description

    -- Mark as Processed
    Update dbo.ManualEntries Set @Status = NULL Where EMID=@emid
End
Go
