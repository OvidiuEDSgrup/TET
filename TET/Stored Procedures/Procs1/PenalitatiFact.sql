--***
create procedure PenalitatiFact(@datas datetime) as 
begin
	--declare @datas datetime	set @datas= '2009-12-31'
	if not exists (select 1 from sys.objects where name='penalizarifact' and type='U') return
	declare @subunitate char(1) set @subunitate = '1'
	declare @data_ucc datetime,@cod varchar(20), @cont_fact_penaliz varchar(20), @comanda varchar(20), @cont_de_stoc varchar(20)
	set @cod='410080001'	set @cont_fact_penaliz='4111.4' set @comanda='1 0 01331050'	
	set @cont_de_stoc=isnull((select max(cont) from nomencl where cod=@cod), '719.1')
	---------
	---stergerea penalizarilor si a documentelor aferente din perioada in care se genereaza penalitati
	delete from penalizarifact where data_penalizare = @datas
	delete from pozdoc where utilizator = 'ASiS' and cod_intrare = 'APBK' and subunitate = @subunitate and barcod='Penalizari' and tip = 'AS' and data = @datas --and left(factura,2)='P#'
	delete facturi from facturi p where abs(valoare)<0.01 and abs(sold)<0.01 and data= @datas
	delete doc from doc p where abs(valoare)<0.01 and numar_dvi='Penalizari' and tip='AS' and data= @datas
	---------

	declare @tipuri_facturare varchar(100),@tipuri_incasare varchar(100) 
	set @tipuri_facturare='AP,AS' set @tipuri_incasare='IB,C3,CO,CB,BX'

	set @data_ucc='2008-6-1'
	if exists (select 1 from penalizarifact) -- alegerea datei ultimului calcul
			set @data_ucc = (select max(data_penalizare) from penalizarifact)

	select ft.* into #documente from fFacturi('B', null,@datas,null,null,null,null,null,0, null, null) ft
	inner join infotert t on ft.tert = t.tert where ((valoare=0 and tva=0) or data_scadentei < @datas) and t.Observatii != 'X' --documente
	and ft.subunitate=@subunitate and charindex(left(tip,2),@tipuri_incasare+','+@tipuri_facturare)<>0

	-- incasari din fFacturi
	select d2.tert,d2.factura,d2.tip,d2.data,d2.numar,sum(d2.achitat) as achitat 
	into #incasari 
	from #documente d2
		where charindex(left(d2.tip,2),@tipuri_incasare)<>0
		group by d2.tert,d2.factura,d2.tip,d2.data,d2.numar
	-- sold pe facturi din fFacturi
	select max(isnull(p.contract,'')) as contract, max(d2.tip) as tip,d2.tert,d2.factura,sum(d2.valoare+d2.tva) as sold, max(d2.data_scadentei) as data_scadentei,
		max(p.loc_de_munca) as loc_de_munca,max(p.grupa) as grupa,max(p.gestiune) as gestiune
	into #sold 
	from #documente d2 
	left join pozdoc p on d2.tip=p.tip and d2.subunitate = p.subunitate and d2.numar = p.numar 
		and d2.data = p.data and d2.tip = p.tip and d2.numar_pozitie = p.numar_pozitie
	where charindex(d2.tip,@tipuri_facturare)<>0 and p.cod<>@cod
	group by d2.tert,d2.factura
	having sum(d2.valoare+d2.tva)-sum(case when d2.data<=@data_ucc then d2.achitat else 0 end)>=0.01
	-- calcul zile si sold pt. penalizare
	select d2.tert,d2.factura,d2.tip,d2.data,d2.numar,max(s.sold)+isnull(-sum(d1.achitat),0) as sold_pen,
		datediff(day,max(case when @data_ucc>isnull(d1.data,'1901-1-1') and @data_ucc>s.data_scadentei then @data_ucc
			when isnull(d1.data,'1901-1-1')>s.data_scadentei then d1.data else s.data_scadentei end),d2.data
				) as zile_pen 
	into #date_pen
	from #incasari d2
	left join #incasari d1 on d1.tip=d2.tip and d1.tert=d2.tert and d1.factura=d2.factura and 
				(d1.data<d2.data or d1.data=d2.data and d1.numar<d2.numar)
	inner join #sold s on d2.factura=s.factura and d2.tert=s.tert
	group by d2.tert,d2.factura,d2.tip,d2.data,d2.numar	
	having d2.data>max(case when @data_ucc>isnull(d1.data,'1901-1-1') and @data_ucc>s.data_scadentei then @data_ucc when isnull(d1.data,'1901-1-1')>s.data_scadentei then d1.data else s.data_scadentei end)
	--calcularea penalizarilor la fiecare incasare
	insert into #date_pen
	select s.tert,s.factura,'NE' as tip,@datas,'', max(s.sold)+isnull(-sum(d1.achitat),0) as sold_pen,
		datediff(day,	-- daca avem penalizare nou 
		(case when max(ps.data_penalizare) is not null then max(ps.data_penalizare) when max(pf.data_penalizare) is not null then max(pf.data_penalizare)
			else max(case when @data_ucc>isnull(d1.data,'1901-1-1') and @data_ucc>s.data_scadentei then @data_ucc
					when isnull(d1.data,'1901-1-1')>s.data_scadentei then d1.data else s.data_scadentei end) end),@datas
				) as zile_pen
		from #incasari d1 right join #sold s on d1.factura=s.factura and d1.tert=s.tert 
			left join (select tert,factura_penalizata,max(data_penalizare) as data_penalizare from penalizarifact p where tip_doc_incasare='NE' group by tert,factura_penalizata) pf on pf.tert=s.tert and pf.factura_penalizata=s.factura
			left join (select tert,factura,max(data) as data_penalizare from #date_pen p group by tert,factura) ps on ps.tert=s.tert and ps.factura=s.factura
		group by s.tert,s.factura 
	having max(s.sold)+isnull(-sum(d1.achitat),0)>0.1		-- penalizari la @datas (cu soldul final)
	order by s.tert,s.factura

	-- luare date din contract 
	select max(s.tip) tip,s.tert,s.factura,max(d.tip) tipd,left(max(d.numar),8) numar,d.data,max(d.sold_pen)sold_pen,max(d.zile_pen)zile_pen,
		max(d.sold_pen*d.zile_pen*(case when isnumeric(e.camp_2)=1 then convert(float,e.camp_2) else 0 end)/100) s_p,max(c.scadenta) scadenta
	into #p	
	from #date_pen d 
	inner join #sold s on d.tert=s.tert and d.factura=s.factura
	inner join con c on c.tert=s.tert and c.contract=s.contract
	inner join (select max(e.camp_2) as camp_2,contract,tert from extcon e where e.tip='BF' group by contract,tert) e 
					on c.contract_coresp = e.contract and c.tert = e.tert
	where sold_pen>0 and zile_pen>0 and d.sold_pen*d.zile_pen*(case when isnumeric(e.camp_2)=1 then convert(float,e.camp_2) else 0 end)/100>1
		and not exists (select 1 from penalizarifact pf where pf.factura_penalizata=s.factura and pf.tert=d.tert and pf.data_doc_incasare>=d.data)
		group by s.tert,s.factura,d.data
		order by s.tert,s.factura,d.data
	-- completare penalizari:
	insert into penalizarifact(Tip, Tert, Factura, Factura_penalizata, Tip_doc_incasare, Nr_doc_incasare, Data_doc_incasare, Sold_penalizare, Data_penalizare, Zile_penalizare, Suma_penalizare, Valuta_penalizare)
	select tip, tert, '' as factura, factura as factura_penalizata, tipd, numar, data, sold_pen, @datas as data_incasare, zile_pen, s_p,'' as valuta
	from #p d where not exists (select 1 from penalizarifact pf where pf.factura_penalizata=d.factura and pf.tert=d.tert and pf.tip=d.tip and d.tipd=pf.tip_doc_incasare and pf.nr_doc_incasare=d.numar and pf.data_doc_incasare>=d.data)
	-- numar de factura temporar:
	declare @off_pdiez int
	select @off_pdiez=max(replace(numar,'P#','')) from pozdoc where left(numar,2)='P#'
	set @off_pdiez=isnull(@off_pdiez,0)

	update penalizarifact set factura='P#'+convert(varchar(6),p.numar) from 
		(select p.tert,s.loc_de_munca,@off_pdiez+row_number() over (order by p.tert) as numar from penalizarifact p inner join #sold s on p.factura_penalizata=s.factura and p.tert=s.tert
			where p.factura='' group by p.tert,s.loc_de_munca) 
			p where p.tert=penalizarifact.tert and penalizarifact.factura='' and 
			exists (select 1 from #sold s where s.tert=p.tert and s.loc_de_munca=p.loc_de_munca and 
						s.factura=penalizarifact.factura_penalizata and s.tert=penalizarifact.tert)

	-- completare pozdoc:
	insert into pozdoc (Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos,
		Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
		Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator,Tip_miscare,Locatie, 
		Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, 
		Gestiune_primitoare, Numar_DVI, Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama,
		Suprataxe_vama, Accize_cumparare, Accize_datorate, Contract, Jurnal)
	select @subunitate,'AS', max(p.factura),
		@cod,@datas,max(s.gestiune),1, sum(suma_penalizare), 0,0,sum(suma_penalizare),sum(suma_penalizare),0,19, 'ASiS', 
		convert(datetime, convert(char(10), getdate(), 104), 104),replace(convert(char(8),getdate(), 108), ':', ''),
		'APBK',@cont_de_stoc,@cont_fact_penaliz,0,0,'V','',@datas,1,
		s.loc_de_munca,@comanda,'Penalizari','',@cont_de_stoc,0,p.tert,max(p.factura),'','',5,max(s.grupa),
		@cont_fact_penaliz,'',0,@datas,@datas
		,0,0,0,0,max(s.contract),''
	from penalizarifact p inner join #sold s on p.factura_penalizata=s.factura and p.tert=s.tert
	where p.data_penalizare=@datas
	group by p.tert,s.loc_de_munca

	drop table #date_pen drop table #documente drop table #incasari drop table #sold drop table #p
end
