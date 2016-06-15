--***

create procedure wacTipMiscari(@sesiune varchar(50), @parXML XML)
as
begin
	declare @searchText varchar(100), @raport varchar(100), @TipLista varchar(100)
	select	@searchText=replace(isnull(@parXML.value('(row/@searchText)[1]','varchar(100)'),' '),' ','%'),
			@raport=rtrim(isnull(@parXML.value('(row/@raport)[1]','varchar(100)'),'')),
			@TipLista=rtrim(isnull(@parXML.value('(row/@TipLista)[1]','varchar(100)'),''))
	
	select * from
	(select 'IT' as cod,'IT - (Toate intrarile)' as denumire union all
	select 'IAF','IAF - Achizitii de la furnizori' union all
	select 'IPF','IPF - Punere in functiune' union all
	select 'IPP','IPP - Productie proprie' union all
	select 'IDO','IDO - Intrare prin donatie' union all
	select 'IAS','IAS - Aport de la asociati' union all
	select 'IAI','IAI - Aportul intreprinzatorui' union all
	select 'ISU','ISU - Intrare de la subunitati' union all
	select 'IAL','IAL - Alte intrari' union all
	select 'ET','ET - (Toate iesirile)' union all
	select 'ECS','ECS - Iesire prin casare' union all
	select 'EVI','EVI - Iesire prin vanzare' union all
	select 'ERE','ERE - Iesire prin retragere' union all
	select 'ESU','ESU - Iesire la subunitati' union all
	select 'EAL','EAL - Alte iesiri' union all
	select 'MT','MT - (Toate modificarile)' union all
	select 'MAI','MAI - Modificare accesorii incluse' union all
	select 'MFF','MFF - Modificare factura furnizor' union all
	select 'MEP','MEP - Modificare prin iesire partiala' union all
	select 'MPP','MPP - Modificare din productie proprie' union all
	select 'MPF','MPF - Punere in functiune' union all
	select 'MMF','MMF - Trecere la m.f.de natura ob.inv.' union all
	select 'MRE','MRE - Modificari prin reevaluare' union all
	select 'MTO','MTO - Trecere la ob. de inv.' union all
	select 'MAL','MAL - Alte modificari' union all
	select 'TT','TT - (Toate transferurile)' union all
	select 'TSE','TSE - Transferuri intre sectii' union all
	select 'TGE','TGE - Transferuri intre gestiuni' union all
	select 'TSU','TSU - Transferuri intre subunitati' union all
	select 'CON','CON - Conservari' union all
	select 'BIN','BIN - Inchirieri'
	) as p
	where (@raport<>'Lista miscari' or left(p.cod,len(@TipLista))=@TipLista) and
		(p.denumire like '%'+@searchText+'%')
	for xml raw
end
