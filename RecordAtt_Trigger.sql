set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[RecordAtt_Trigger]
   ON  [dbo].[tEnter]
   AFTER INSERT
AS 
BEGIN

	IF @@ROWCOUNT = 0
		RETURN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @date char(8)
	DECLARE @time char(6)
	DECLARE @tid  int
	DECLARE @uid  int

	SELECT @date=C_Date, @time=C_Time, @tid=L_TID, @uid=L_UID FROM INSERTED

	DECLARE @datetime varchar(20)
	SET @datetime = @date + ' ' + SUBSTRING(@time, 1, 2) + ':' + SUBSTRING(@time, 3, 2)+ ':' + SUBSTRING(@time, 5, 2)
	DECLARE @mydate DATETIME
	DECLARE @mytime DATETIME
	SET @mydate = CAST(@date as DATETIME);
	SET @mytime = CAST(@datetime as DATETIME);

	EXEC Ice_Project_Directory.dbo.RecordEntry @eid=@uid, @tid=@tid, @date=@mydate, @time=@mytime;

END


