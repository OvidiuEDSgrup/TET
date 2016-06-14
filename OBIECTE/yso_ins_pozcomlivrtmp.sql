ALTER trigger dbo.yso_ins_pozcomlivrtmp on [dbo].[pozcomlivrtmp] instead of INSERT as

DECLARE @tSQLLog TABLE 
	(language_event NVARCHAR(100)
	,parametri INT
	,comanda NVARCHAR(4000)
	,moment DATETIME DEFAULT CURRENT_TIMESTAMP)
DECLARE @comanda NVARCHAR(4000), @filtruStare nvarchar(50), @stare char(3)

INSERT INTO @tSQLLog (language_event, parametri, comanda)
EXEC('DBCC INPUTBUFFER(@@SPID) WITH NO_INFOMSGS;') AS LOGIN = 'sa'; 
select top 1 @comanda=comanda from @tsqllog
--print @comanda
set @comanda=substring(@comanda,CHARINDEX('insert into pozcomlivrtmp',@comanda),4000)
SET @comanda=SUBSTRING (@comanda,CHARINDEX(')',@comanda)+1,4000) 
SET @comanda=SUBSTRING (@comanda,1,CHARINDEX('group by p.cod, p.contract, p.tert',@comanda)+36)
--set @comanda=replace(REPLACE(@comanda,'p.cant_realizata','0'),'p.pret_promotional','0')
--print @comanda
set @filtruStare=SUBSTRING(@comanda,PATINDEX('%c.stare = ''_''%',@comanda),13)
print @filtruStare
set @stare=RIGHT(rtrim(@filtruStare),3)
set @filtruStare='c.stare = isnull(nullif('+@stare+','' ''),c.stare)'
SET @comanda=STUFF(@comanda,PATINDEX('%c.stare = ''_''%',@comanda),13,@filtruStare)
print @comanda
print @filtruStare
Print @stare
INSERT INTO pozcomlivrtmp
EXEC(@comanda) AS LOGIN='sa'
