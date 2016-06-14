declare @sesiune nvarchar(13),@cont nvarchar(6),@data datetime,@numar nvarchar(6),@numeTabelTemp nvarchar(4000)
select @sesiune=N'3A98BF98F6AA3',@cont=N'5311.1',@data='2014-03-31 00:00:00',@numar=N'115M21',@numeTabelTemp=NULL
declare @parXML xml
set @parxml = (select @cont cont, @data data, @numar numar, @numeTabelTemp numeTabelTemp for xml raw)
exec rapFormDispozitiePlata @sesiune=@sesiune, @parXML=@parXML, @numetabelTemp=@numeTabelTemp