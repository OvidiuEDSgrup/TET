create procedure wIaTipTVATert @sesiune varchar(50), @parXML xml
as
	declare 
		@tert varchar(20)

	set @tert=@parXML.value('(/*/@tert)[1]','varchar(20)')

	select 
		convert(varchar(10),t.dela,101) as data_inceput, t.tip_tva as cod_tip_tva,
		(case  t.tip_tva  when 'N' then 'Neplatitor' when 'P' then 'Platitor' when 'I' then 'Incasare' end ) den_tip_tva,
		t.idTvaPeTert id_tva_pe_tert
	from  TvaPeTerti t
	where t.tipf='F' and t.tert=@tert and factura is null
	for xml raw, root('Date')
