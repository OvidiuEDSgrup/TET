--***
create PROCEDURE [dbo].[returneaza_pardata] @dataj datetime, @datas datetime, @raport VARCHAR(1000), @BDr varchar(20),         
      @output VARCHAR(500) OUTPUT          
          
           
AS          
               
set @raport = replace(@raport,'<F>','')          
if @raport is null set @raport=''
            
  
declare @sql varchar(8000)         
            
set @sql = 'SELECT '''+@raport+''' AS e,          
            c.parameter parametrii_xml,          
    CASE WHEN PATINDEX(''%&%'','''+@raport+''')<>0 THEN          
                STUFF(REVERSE(STUFF(LTRIM(REVERSE('''+@raport+''')),PATINDEX(''%/%'',LTRIM(REVERSE('''+@raport+'''))),  
     LEN(LTRIM(REVERSE('''+@raport+'''))),'''')),          
                    PATINDEX(''%&%'',REVERSE(STUFF(LTRIM(REVERSE('''+@raport+''')),PATINDEX(''%/%'',LTRIM(REVERSE('''+@raport+'''))),LEN(LTRIM(REVERSE('''+@raport+'''))),''''))),          
                    LEN(REVERSE(STUFF(LTRIM(REVERSE('''+@raport+''')),PATINDEX(''%/%'',LTRIM(REVERSE('''+@raport+'''))),LEN(LTRIM(REVERSE('''+@raport+'''))),''''))),'''')          
    ELSE          
                REVERSE(STUFF(LTRIM(REVERSE('''+@raport+''')),PATINDEX(''%/%'',LTRIM(REVERSE('''+@raport+'''))),LEN(LTRIM(REVERSE('''+@raport+'''))),''''))          
    END AS nume_raport          
            INTO ##tmp          
    FROM detalind d          
            LEFT OUTER JOIN '+rtrim(ltrim(@BDr)) +'..catalog c ON          
            c.name=CAST(CASE WHEN PATINDEX(''%&%'','''+@raport+''')<>0 THEN          
                    STUFF(REVERSE(STUFF(LTRIM(REVERSE('''+@raport+''')),PATINDEX(''%/%'',LTRIM(REVERSE('''+@raport+'''))),LEN(LTRIM(REVERSE('''+@raport+'''))),'''')),          
                        PATINDEX(''%&%'',REVERSE(STUFF(LTRIM(REVERSE('''+@raport+''')),PATINDEX(''%/%'',LTRIM(REVERSE('''+@raport+'''))),LEN(LTRIM(REVERSE('''+@raport+'''))),''''))),          
                        LEN(REVERSE(STUFF(LTRIM(REVERSE('''+@raport+''')),PATINDEX(''%/%'',LTRIM(REVERSE('''+@raport+'''))),LEN(LTRIM(REVERSE('''+@raport+'''))),''''))),'''')          
        ELSE          
                    REVERSE(STUFF(LTRIM(REVERSE('''+@raport+''')),PATINDEX(''%/%'',LTRIM(REVERSE('''+@raport+'''))),LEN(LTRIM(REVERSE('''+@raport+'''))),''''))          
        END AS CHAR(1000)) collate Latin1_General_CI_AS_KS_WS          
        AND ''/''+(CASE WHEN PATINDEX(''%&%'','''+@raport+''')<>0 THEN SUBSTRING('''+@raport+''',0,PATINDEX(''%&%'','''+@raport+'''))           
        ELSE '''+@raport+''' END)=          
            c.path          
    WHERE d.tip_detaliere=''R''           
        AND d.expresie=''<F>''+'''+@raport+''''    
  --print @sql

exec (@sql)    
  
DECLARE @text xml          
DECLARE @idoc INT          
--begin try
    SET @text = (          
    SELECT  TOP 1 CAST(parametrii_xml AS xml)           
        FROM ##tmp)          
--end try
--begin catch
--end catch
EXEC sp_xml_preparedocument @idoc output, @text          
SELECT IDENTITY(INT,1,1) AS id,d.TEXT nume_par,b.TEXT tip_par          
            INTO ##tmp_par          
    FROM openxml(@idoc,'Parameters/Parameter/Type',2) a          
            LEFT OUTER JOIN openxml(@idoc,'Parameters/Parameter/Type',2) b ON b.parentid=a.id          
            LEFT OUTER JOIN openxml(@idoc,'Parameters/Parameter/Name',2) c ON c.parentid=a.parentid          
            LEFT OUTER JOIN openxml(@idoc,'Parameters/Parameter/Name',2) d ON d.parentid=c.id          
    WHERE a.localname='Type'          
        AND CAST(b.TEXT AS CHAR(100))='Datetime'          
EXEC sp_xml_removedocument @idoc          
          
--SELECT * FROM ##tmp_par          
          
DECLARE  @par VARCHAR(500), @tip VARCHAR(500), @id INT          
    
if exists (select * from ##tmp where e like '%Documente pe terti%')    
begin    
      
 DECLARE cursor_output CURSOR FOR        
 SELECT *         
  FROM ##tmp_par        
 OPEN cursor_output        
    FETCH next         
  FROM cursor_output INTO @id,@par,@tip     
 SET @output = ''        
 WHILE (@@fetch_status=0)        
  BEGIN      
  SET @output=rtrim(isnull(@output,''))+'&'+RTRIM(@par)+'='+(CASE        
       WHEN (        
     SELECT COUNT(*)         
      FROM ##tmp_par)>1         
      AND @id in (1,2,4) THEN CONVERT(CHAR(10),@dataj,120)        
    ELSE CONVERT(CHAR(10),@datas,120)        
    END)--+''''        
     FETCH next         
   FROM cursor_output INTO @id,@par,@tip        
  END        
    CLOSE cursor_output        
    DEALLOCATE cursor_output        
end    
else    
begin    
    
 --DECLARE  @par VARCHAR(500), @tip VARCHAR(500), @id INT        
 DECLARE cursor_output CURSOR FOR        
 SELECT *         
  FROM ##tmp_par        
 OPEN cursor_output        
    FETCH next         
  FROM cursor_output INTO @id,@par,@tip     
 SET @output = ''        
 WHILE (@@fetch_status=0)        
  BEGIN      
  SET @output=rtrim(isnull(@output,''))+'&'+RTRIM(@par)+'='+(CASE        
       WHEN (        
     SELECT COUNT(*)         
      FROM ##tmp_par)>1         
      AND @id = 1 THEN CONVERT(CHAR(10),@dataj,120)        
    ELSE CONVERT(CHAR(10),@datas,120)        
    END)--+''''        
     FETCH next         
   FROM cursor_output INTO @id,@par,@tip        
  END        
    CLOSE cursor_output        
    DEALLOCATE cursor_output        
    
end    


drop table ##tmp  
drop table ##tmp_par  
--SELECT @output          
          --exec returneaza_pardata '2007-08-01','2007-08-31','CG/Stocuri/Situatii intrari iesiri&tip_doc=AP&tip_doc=AS'          
    --select * from detalind          
    --select * from reportserver..catalog order by name 
