Use TestDb;

-- Ensure that a Manual Entry table exists
If Not Exists (
    Select * from sys.objects
    Where object_id = OBJECT_ID(N'dbo.ManualEntries') AND type in (N'U')
) Begin
Create Table dbo.ManualEntries (
    MEID Int NOT NULL Identity(1, 1) PRIMARY KEY,
    EmployeeCode Int NOT NULL,
    TrackDate DateTime NOT NULL,
    InTime DateTime NOT NULL,
    OutTime DateTime NOT NULL,
    Status varchar(10) NULL,
)
End

Select * from EmployeeAttendance Where employeeid = 107 and DatePart(yy, attendanceDate) = 2018 and attendanceStatus='A'

-- Get all the unprocessed entries
Declare eCursor CURSOR FOR
    Select MEID, EmployeeCode, TrackDate, InTime, OutTime
    From dbo.ManualEntries
    Where Status = 'Pending'

Open eCursor

Declare @meid int
Declare @employeeCode int
Declare @trackDate DateTime
Declare @inTime DateTime
Declare @outTime DateTime


-- Process all Entries one by one
Fetch Next From eCursor Into @meid, @employeeCode, @trackDate, @inTime, @outTime
While @@Fetch_Status = 0 Begin
    Exec dbo.RecordManualEntry @emid, @employeeCode, @trackDate, @inTime, @outTime
End

Close eCursor
Deallocate eCursor
