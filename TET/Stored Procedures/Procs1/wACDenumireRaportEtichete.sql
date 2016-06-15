--***
create procedure wACDenumireRaportEtichete @sesiune varchar(50), @parXML xml
as
begin try
	declare @eroare varchar(1000), @bdrep varchar(100), @xml xml, @path varchar(2000), @fara_luare_date int,
			@comanda nvarchar(4000)

	select @bdrep=rtrim(val_alfanumerica) from par where tip_parametru='AR' and parametru='REPSRVBAZ'
	set @bdrep=(case when isnull(@bdrep,'') = '' then 'ReportServer' else @bdrep end)
	
	if OBJECT_ID('tempdb..#rapoarte') is not null
		drop table #rapoarte

	create table #rapoarte(cod varchar(5000), denumire varchar(5000))

	set @comanda=
	'insert into #rapoarte(cod, denumire)
	select [path], name
	from ['+@bdrep+']..catalog
	where [Type] = ''2''
	'
	exec sp_executesql @statement=@comanda--, @params=N'@path as varchar(2000), @xml as xml output', @path=@path, @xml=@xml output

	select top 100
		rtrim(cod) as cod,
		rtrim(denumire) as denumire
	from #rapoarte
	where denumire like '%etichet%'
	for xml raw

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
