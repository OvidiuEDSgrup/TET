
create procedure wmIaLocatii @sesiune varchar(50), @parXML xml
as
begin
	declare 
		@locatie_parinte varchar(20), @searchText varchar(max), @locatie_scanata varchar(20)

	set @locatie_parinte=ISNULL(@parXML.value('(/*/@cod)[1]','varchar(20)'),'')
	set @searchText=@parXML.value('(/*/@searchText)[1]','varchar(max)')

	select 
		@locatie_scanata=@searchText,
		@searchText = '%'+ ISNULL(@searchText,'')+ '%'

	exec CalculStocLocatii @sesiune=@sesiune, @parXML ='' 
	IF EXISTS (select 1 from locatii where Cod_locatie=@locatie_scanata) and NOT EXISTS (select 1 from locatii where Cod_grup=@locatie_scanata)
	BEGIN
		declare @xmlStoc xml

		set @xmlStoc=(select @locatie_scanata cod for xml raw)
		exec wmIaStocuriLocatie @sesiune=@sesiune, @parXML=@xmlStoc
		return			
	END

	select
		rtrim(l.cod_locatie) cod, '1' as _toateAtr, rtrim(l.descriere)+' ('+rtrim(l.cod_locatie)+')' denumire,
		ISNULL('Gestiune: '+rtrim(g.denumire_gestiune) ,'') + 
		'/ Cap. '+convert(varchar(10), convert(decimal(15,2), l.capacitate)) +'/ Disp. '+convert(varchar(10), convert(decimal(15,2), l.capacitate-t.stoc))as info,
		(case when not exists (select 1 from locatii where cod_grup=l.Cod_locatie) then 'wmIaStocuriLocatie' else 'wmIaLocatii' end) as procdetalii
	from Locatii l
	LEFT JOIN um on um.um=l.um
	left join tmpStocPeLocatii t on t.cod_locatie=l.Cod_locatie
	LEFT JOIN gestiuni g on g.cod_gestiune=l.cod_gestiune
	where (l.cod_grup=@locatie_parinte OR len(@searchText)>6) and (l.cod_locatie like @searchText OR l.Descriere like @searchText) 
	for xml raw, root('Date')

	select 'qrcode' as areSearchQr, '1' as areSearch
	for xml raw, root('Mesaje')

end
