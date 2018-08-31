Declare @code int;
-- SET @code=9301019
SET @code=9600497


-- SELECT * from FPEntries where L_UID = @code
-- order by C_date, C_time


Select top(100) 
    convert(varchar(10), TrackDate, 102) as Date,
    convert(Varchar(10), InOutTime, 108) as Time,
    InOutStatus,
    Employee.EmployeeCode
From
    attendancedetails
    Join employee on employee.employeeid = attendancedetails.employeeid
Where employeecode = convert(varchar, @code)
Order By adid Desc


Select Distinct
    Replace(Convert(Char(20), Checktime, 102), '.', '') AS C_Date,
    Replace(Convert(Char(20), Checktime, 108), ':', '') AS C_Time,
    (Case When checktype='I' Then 1 Else 2 End) As L_TID,
    Cast(badgenumber As Int) As L_UID
From zkt.dbo.Checkinout Join zkt.dbo.Userinfo On zkt.dbo.Checkinout.Userid = zkt.dbo.Userinfo.Userid
Where zkt.dbo.userinfo.badgenumber=@code
Order By C_Date Desc, C_Time Desc


Select Distinct *
From UNIS.dbo.tEnter
Where L_UID = @code
Order By C_Date Desc

