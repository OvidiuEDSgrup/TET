--***
create procedure wOPAnulareFacturaSA @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@nrdeviz varchar(50), @tipdeviz varchar(1), @numardoc varchar(20),
		@stare varchar(1), @data datetime, @docJurnal xml, @stareJurnal int,
		@dataJurnal datetime

	select
		@nrdeviz = isnull(@parXML.value('(/parametri/@nrdeviz)[1]', 'varchar(50)'), ''),
		@tipdeviz = isnull(@parXML.value('(/parametri/@tipdeviz)[1]', 'varchar(1)'), ''),
		@numardoc = @parXML.value('(/parametri/@nrdoc)[1]', 'varchar(20)'),
		@stare = @parXML.value('(/parametri/@stare)[1]', 'varchar(1)'),
		@data = isnull(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')

	if @nrdeviz = ''
		raiserror('Devizul nu s-a putut identifica!', 16, 1)
	if @tipdeviz <> 'N' or @stare <> '3' or @numardoc is null
		raiserror('Devizul nu a fost facturat sau factura a fost deja anulata!', 16, 1)

	delete from pozdoc where tip = 'AP' and numar = @numardoc and data = @data

	update d
	set d.Stare = '2', d.Tip = ''
	from devauto d
	where d.Cod_deviz = @nrdeviz

	update pd
	set pd.Stare_pozitie = '2'
	from pozdevauto pd
	where pd.Cod_deviz = @nrdeviz

	set @stareJurnal = (select top 1 convert(int, Stare) from devauto where Cod_deviz = @nrdeviz)
	set @dataJurnal = (select top 1 Data_lansarii from devauto where Cod_deviz = @nrdeviz)

	set @docJurnal = (select @nrdeviz as nrdeviz, @stareJurnal as stare, @dataJurnal as data, 'Anulat factura' as explicatii for xml raw, type)
	exec wScriuJurnalDeviz @sesiune = @sesiune, @parXML = @docJurnal

	select 'S-a anulat factura cu nr. ' + rtrim(@numardoc) + ' si cu data ' + convert(varchar(10), @data, 103) + '.' as textMesaj
	for xml raw, root('Mesaje')

end try
begin catch
	declare @mesajEroare varchar(50)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
