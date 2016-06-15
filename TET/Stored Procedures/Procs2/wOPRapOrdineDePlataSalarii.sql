create procedure wOPRapOrdineDePlataSalarii @sesiune varchar(50), @parXML xml
as
set transaction isolation level READ UNCOMMITTED  
begin try
	declare @utilizator varchar(100), @data datetime,@idOP int, @contContabil varchar(20), @afisareDateEmiterii int, 
		@codFormular varchar(100), @xml xml,@eroare varchar(4000)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  

	select	@data=isnull(@parXML.value('(/row/@data)[1]','datetime'),GETDATE()),
			@idOP=@parXML.value('(/parametri/@idOP)[1]','int'),
			@afisareDateEmiterii=@parXML.value('(/parametri/@afisdata)[1]','int')
	
	select @contContabil=cont_contabil from OrdineDePlata where idOP=@idOP
	if left(@contContabil,4)='5311'
		set @codFormular='/PS/Foi de varsamant contributii'
	else
		set @codFormular='/PS/Ordine de plata contributii'
	
	-- generare formular din raport
	set @xml = 
		(select 'OP_'+rtrim(convert(int,@idOP))+'_'+left(convert(char(10),@data,101),2)+right(convert(char(10),@data,101),4) numeFisier, 
			@codFormular caleRaport, DB_NAME() BD, @idOP idOP, @afisareDateEmiterii as afisdata, @sesiune sesiune, 
			convert(varchar(10),@data,120) data, 'pdf417' tipBarcode
		for xml raw)
	exec wExportaRaport @sesiune=@sesiune, @parXML=@xml
	
end try
begin catch
	set @eroare=ERROR_MESSAGE() 
	raiserror(@eroare, 16, 1) 
end catch	
