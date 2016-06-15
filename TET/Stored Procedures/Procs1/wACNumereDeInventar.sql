--***
CREATE procedure wACNumereDeInventar @sesiune varchar(50),@parXML XML
as
if exists(select * from sysobjects where name='wACNumereDeInventarSP' and type='P')
	exec wACNumereDeInventarSP @sesiune,@parXML
else 
begin
	declare @Sb varchar(9), @searchText varchar(80), @tip varchar(2), @data datetime, @tert varchar(20)

	select @Sb=''
	select @Sb=(case when tip_parametru='GE' and parametru='SUBPRO' then val_alfanumerica else @Sb end)
	from par 

	select	@searchText=isnull(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
			@tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
			@data=isnull(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'),
			@tert=isnull(@parXML.value('(/row/detalii/row/@tert)[1]', 'varchar(20)'), '')
	
	select @searchText=REPLACE(@searchText, ' ', '%')
		
	select top 100
	rtrim(mf.Numar_de_inventar) as cod,
		'Cantitate '+ltrim(rtrim(convert(char(18),convert(decimal(11,5),f.Cantitate)))) as info,
		ltrim(rtrim(mf.Denumire)) as denumire
	from mfix mf
		inner join fisamf f on f.Subunitate=mf.Subunitate and f.Numar_de_inventar=mf.Numar_de_inventar and f.Felul_operatiei='1' and f.Data_lunii_operatiei=dbo.EOM(@data)
	where mf.subunitate=@Sb 
		and (mf.Numar_de_inventar like @searchText+'%' or mf.Denumire like '%'+@searchText+'%')
		and mf.detalii.value('(/row/@tert)[1]', 'varchar(20)')=@tert
	order by rtrim(mf.Numar_de_inventar)
	for xml raw
end
