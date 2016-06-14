
SELECT  * 
FROM    OPENROWSET ('SQLOLEDB','Server=(local);TRUSTED_CONNECTION=YES;','set fmtonly off exec master.dbo.sp_who')

SELECT * INTO #tbl_test FROM
    OPENROWSET(
        'SQLNCLI',
        'Server=(local);trusted_connection=yes',
        'set fmtonly off exec db_test.dbo.xml_test') AS tbl_test;
GO
DECLARE @guid varchar(36),@TableSrc varchar(100)='um';  select @guid= convert(varchar(36), NEWID() );
/*
    The one caveat to this technique is that ##ContextSpecificGlobal__Temp should ALWAYS have the exact same columns.  
    So make up your global temp table name in the sproc you're using it in and only there!
    In this example I wanted to pass in the name of a global temporary table dynamically.  I have 1 procedure dropping 
    off temporary data in whatever @TableSrc is and another procedure picking it up but we are dynamically passing 
    in the name of our pickup table as a parameter for OPENQUERY.
*/
IF ( OBJECT_ID('tempdb..##ContextSpecificGlobal__Temp' , 'U') IS NULL )
    EXEC ('SELECT * INTO ##ContextSpecificGlobal__Temp FROM OPENQUERY(ASIS, ''Select *,''''' +  @guid +''''' as tempid FROM ' + @TableSrc + ''')')
ELSE 
    EXEC ('INSERT ##ContextSpecificGlobal__Temp SELECT * FROM OPENQUERY(ASIS, ''Select *,''''' +  @guid +''''' as tempid FROM ' + @TableSrc + ''')')

--If this proc is run frequently we could run into race conditions, that's why we are adding a guid and only deleting
--the data we added to ##ContextSpecificGlobal__Temp
SELECT * INTO #TableSrc FROM ##ContextSpecificGlobal__Temp WHERE tempid = @guid

BEGIN TRAN t1
    IF ( OBJECT_ID('tempdb..##ContextSpecificGlobal__Temp' , 'U') IS NOT NULL ) 
    BEGIN
        -- Here we wipe out our left overs if there if everyones done eating the data
        IF (SELECT COUNT(*) FROM ##ContextSpecificGlobal__Temp) = 0
            DROP TABLE ##ContextSpecificGlobal__Temp
    END
COMMIT TRAN t1

-- YEAH! Now I can use the data from my openquery without wrapping the whole !$#@$@ thing in a string.