exec sp_executesql N'declare @parXML xml
set @parXML = (select @cont cont, @data data, @numar numar, @numeTabelTemp numeTabelTemp for xml raw)

exec rapFormChitanta @sesiune=@sesiune,
		@cont=@cont, @data=@data, @numar=@numar, @nrExemplare=@nrExemplare, @parXML=@parXML,
		@numeTabelTemp=@numeTabelTemp',N'@sesiune nvarchar(13),@cont nvarchar(6),@data datetime,@numar nvarchar(8),@nrExemplare nvarchar(1),@numeTabelTemp nvarchar(4000)',@sesiune=N'3A98BF98F6AA3',@cont=N'5311.1',@data='2014-03-17 00:00:00',@numar=N'10000008',@nrExemplare=N'2',@numeTabelTemp=NULL