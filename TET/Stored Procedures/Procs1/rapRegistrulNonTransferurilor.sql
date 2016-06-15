
create procedure rapRegistrulNonTransferurilor (@sesiune varchar(50) =null,
	--@tip varchar(2), @numar varchar(20), @data datetime, @nrExemplare int=1,
	@gestiune varchar(50)=null, @tert varchar(50)=null,
	@plecare_datajos datetime = null, @plecare_datasus datetime=null,
	@sosire_datajos datetime=null, @sosire_datasus datetime=null,
	@cont varchar(50)='%',
	@ordonare varchar(50)='D',
	@parXML xml = NULL)
as
begin try
	set transaction isolation level read uncommitted
	if object_id('tempdb..#registru') is not null drop table #registru
	select @cont=@cont+'%'
			
	select data_plecarii data_plecarii, x.valoare valoare, cod_intrare, rtrim(x.cod) cod, rtrim(t.tert) tert,
		data_sosirii data_sosirii, '('+rtrim(x.cod)+') '+rtrim(n.denumire) denumire_nomenclator, '('+rtrim(t.tert)+') '+rtrim(t.denumire) as nume_tert,
		--> date adaugate pentru test raport, trebuie identificate si completate corect:
			convert(varchar(1000),rtrim(case when t.tert_extern=0 then t.judet else '' end)) judet, 
			convert(varchar(1000),t.localitate) localitate,
			--> adresa, mai putin localitatea si judetul pe care le voi completa cu update mai jos:
				rtrim(adresa)
					
			 adresa ,
			 rtrim(isnull(x.descriere_transportate,n.denumire)) descriere_transportate
			 ,x.cantitate_transportate, (case when x.cantitate_returnate is null then '' else rtrim(isnull(x.descriere_returnate,n.denumire)) end) descriere_returnate, x.cantitate_returnate
			,(case when x.cantitate_nereturnabile is null then '' else rtrim(isnull(x.descriere_nereturnabile,n.denumire)) end) descriere_nereturnabile, x.cantitate_nereturnabile
			,x.numar_nereturnabile numar_doc, x.data_nereturnabile data_doc
		/*
			,'Adresa 1' adresa , 2 cantitate_transportate, 'Descriere r 3' descriere_returnate, 4 cantitate_returnate
			,'Descriere n 5' descriere_nereturnabile, 6 cantitate_nereturnabile, 'nr7' numar_doc, x.data_plecarii data_doc
		--*/
		into #registru
	from
	(select p.idpozdoc, P.numar, p.data data_plecarii , p2.data data_sosirii, p.cantitate * p.pret_de_stoc valoare, p.cod_intrare, rtrim(p.cod) cod
			,p.detalii.value('(row/@explicatii)[1]','varchar(2000)') as descriere_transportate
			,p.cantitate cantitate_transportate, p2.detalii.value('(row/@explicatii)[1]','varchar(2000)') descriere_returnate, p2.cantitate cantitate_returnate
			,p3.detalii.value('(row/@explicatii)[1]','varchar(2000)') descriere_nereturnabile, p3.cantitate cantitate_nereturnabile
			,p3.numar numar_nereturnabile, p3.data data_nereturnabile
		from pozdoc p
			left join pozdoc p2 on p2.idIntrareFirma=p.idpozdoc and p2.tip='AE'
			left join pozdoc p3 on p3.idIntrareFirma=p.idpozdoc and p3.tip='CM'
		where p.tip='AI' and p.Cont_de_stoc like @cont 
		and (@gestiune is null or p.gestiune=@gestiune)
		and (@plecare_datajos is null or p.data >= @plecare_datajos)
		and (@plecare_datasus is null or p.data <= @plecare_datasus)
		and (@sosire_datajos is null or p2.data >= @sosire_datajos)
		and (@sosire_datasus is null or p2.data <= @sosire_datasus)		
	) x 
	inner join doc d on d.Subunitate='1' and d.tip='AI' and d.numar=x.Numar and d.data=x.data_plecarii
		and (@tert is null or d.detalii.value('(row/@tert)[1]','varchar(100)') like @tert)
	left join nomencl n on x.cod=n.cod
	left join terti t on t.tert=d.detalii.value('(row/@tert)[1]','varchar(100)')
					--t.tert='14117850'
	order by (case @ordonare	when 'N' then isnull(n.denumire,'')+'|'+x.cod
								when 'T' then isnull(t.denumire,'')+'|'+t.tert
								else ''
			end), (case @ordonare
								when 'V' then x.valoare
								when 'P' then data_plecarii
								when 'S' then data_sosirii else '' end) desc,
		x.cod, x.cod_intrare

	--> completare cu date tert pentru adresa:
	declare @locterti int, @judterti int
	select	@locterti=max(convert(int, (case when p.parametru='locterti' then val_logica else 0 end))),
		@judterti=max(convert(int, (case when p.parametru='judterti' then val_logica else 0 end)))
	from par p where p.tip_parametru='ge' and p.parametru in ('LOCTERTI','JUDTERTI')

	if  @judterti=1
		update r set judet=rtrim(j.denumire) from #registru r inner join judete j on r.judet=j.cod_judet
			where r.judet<>''
	if @locterti=1
		update r set localitate=rtrim(l.oras) from #registru r inner join localitati l on r.localitate=l.cod_oras

	select data_plecarii, valoare, cod_intrare, cod, tert, data_sosirii, denumire_nomenclator, nume_tert,
		adresa--+localitate+judet
		+rtrim(isnull(', '+nullif(localitate,''),''))
		+isnull(', '+nullif(judet,''),'')
		adresa,
		descriere_transportate, cantitate_transportate, descriere_returnate, cantitate_returnate, descriere_nereturnabile, cantitate_nereturnabile, numar_doc, data_doc
	from #registru

end try
begin catch
	declare @mesajEroare varchar(500) 
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
end catch

	if object_id('tempdb..#registru') is not null drop table #registru
if len(@mesajEroare)>0 raiserror(@mesajEroare, 16, 1)
