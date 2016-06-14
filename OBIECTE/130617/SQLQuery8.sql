declare @procid int=@@procid, @objname sysname
set @objname=object_id(@procid)
EXEC wJurnalizareOperatie @sesiune='', @parXML='', @obiectSql=@objname

select * from webJurnalOperatii 