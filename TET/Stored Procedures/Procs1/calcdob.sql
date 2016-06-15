--***
CREATE PROCEDURE calcdob (@dataj datetime,@datas datetime,@tert varchar(13),@compatibilitateInUrma int=0)
AS

--drop table vdate_pen drop table vdocumente drop table vincasari drop table vsold drop table vp
--declare @datas datetime set @datas= '2011-09-30' declare @dataj datetime set @dataj='2010-12-31'  declare @subunitate char(1) set @subunitate = '1'

declare @data_ucc datetime,@cod varchar(20), @cont_fact_penaliz varchar(20), @comanda varchar(40), @cont_de_stoc varchar(20),@mesaj varchar(200),
	@indbug varchar(20),@subunitate char(1)

begin try 
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	
	exec luare_date_par 'UC', 'CODDOB', 0, 0, @cod output
	if ISNULL(@cod,'')=''
		set @cod='95002'	

	exec luare_date_par 'UC', 'CONTDOB', 0, 0, @cont_fact_penaliz output
	if ISNULL(@cont_fact_penaliz,'')=''
		set @cont_fact_penaliz='411125' 
		
	exec luare_date_par 'UC', 'INDBUGDOB', 0, 0, @indbug output
	if ISNULL(@indbug,'')=''
		set @indbug='1 0 0133205001'
			
	set @comanda=space(20)+@indbug
	set @cont_de_stoc=isnull((select max(cont) from nomencl where cod=@cod), '70851')

	if @tert='' 
		set @tert= null

	declare @tipuri_facturare varchar(100),@tipuri_incasare varchar(100),@grupePenDob varchar(500) 
	set @tipuri_facturare='AP,SI,AS' set @tipuri_incasare='IB,C3,CO,CB,BX'
	set @grupePenDob='100.10.14,100.10.15,100.10.2,100.10.3'
	
	select * into #grupePenDob from dbo.fsplit(@grupePenDob,',')

	set @data_ucc=@dataj
	/*if exists (select 1 from penalizarifact where tip_penalizare='D') -- alegerea datei ultimului calcul
		set @data_ucc = (select max(data_penalizare) from penalizarifact where tip_penalizare='D')*/
--select 'inceput',GETDATE()	
	
	select ft.* 
	into #fFacturi 
	from fFacturi('B', null,@datas,@tert,null,null,null,null,0,null, null) ft
	where ft.subunitate=@subunitate
		and((valoare=0 and tva=0) or data_scadentei < @datas)
		and charindex(left(tip,2),@tipuri_incasare+','+@tipuri_facturare)<>0 
		--and (ft.cont_de_tert like '411%' or ft.cont_de_tert like '4'
	
	--stergere documente de tip SI care nu sunt in pozdoc, sau care sunt facturi de penalitati	
	delete p 
	from #fFacturi p
		inner join pozdoc po on p.Factura=po.Factura and p.Tert=po.Tert and po.Subunitate='1' 
			and po.tip in ('AP','AS') and po.Data_facturii=p.data_facturii
		inner join nomencl n on po.Cod=n.Cod
	where n.Grupa in (select string from #grupePenDob)
		and p.tip='SI'
--select 'dupa fFacturi',GETDATE()
--select '#fFacturi',* from #fFacturi --where factura like '1895%'

	select n.Grupa,ft.* 
	into #documente 
	from #fFacturi ft
		--inner join infotert t on ft.subunitate=t.subunitate and ft.tert = t.tert  and t.Identificator='' and t.Observatii not in  ('X','D') --se genereaza dar se invalideaza
		left join nomencl n on n.Cod=ft.cod
	where not exists (select 1 from penalizarifact p where p.tert=ft.tert and p.data_factura_generata=ft.data_facturii and p.factura_generata=ft.factura)
		and ((rtrim(ltrim(n.Grupa)) not in (select string from #grupePenDob)) or ISNULL(ft.cod,'')='')		

--select '#documente',* from #documente --where factura like '1895%'
	-- incasari din fFacturi
	select d2.tert,d2.factura,d2.tip,isnull((case when d3.data_document='1901-01-01'then null else d3.data_document end),d2.data) data,d2.numar,sum(d2.achitat) as achitat 
	into #incasari 
	from #documente d2 
		left join (select tip, numar, data, data_document, cont, numar_pozitie from extpozplin) d3
			on /*d3.tip=d2.tip and*/ d3.numar=d2.numar and d3.data=d2.data /*and d3.cont=d2.cont_coresp*/ and d3.numar_pozitie=d2.numar_pozitie
	where charindex(left(d2.tip,2),@tipuri_incasare)<>0 and d2.subunitate=@subunitate
	group by d2.tert,d2.factura,d2.tip,isnull((case when d3.data_document='1901-01-01'then null else d3.data_document end),d2.data),d2.numar
	
	Create Clustered Index FactTertInc on #incasari (factura,tert)
--select 'dupa incasari din tert',GETDATE()
--select '#incasari',* from #incasari --where factura like '1895%'

	-- sold pe facturi din fFacturi
	select max(isnull(p.contract,'')) as contract, max(d2.tip) as tip,d2.tert,d2.factura,sum(d2.valoare+d2.tva) as sold, max(d2.data_scadentei) as data_scadentei,
		max(p.loc_de_munca) as loc_de_munca,max(p.grupa) as grupa,max(p.gestiune) as gestiune
	into #sold 
	from #documente d2 
	left join pozdoc p on d2.subunitate = p.subunitate and d2.tip = p.tip and d2.numar = p.numar 
		and d2.data = p.data and d2.numar_pozitie = p.numar_pozitie
	where charindex(d2.tip,@tipuri_facturare)<>0 and p.cod<>@cod and isnull(p.stare,0) not in (4,6) 
	group by d2.tert,d2.factura
	having sum(d2.valoare+d2.tva)-sum(case when d2.data<=dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(d2.tert,'D',0),'1901-01-01'),@dataj) then d2.achitat else 0 end)>=0.01
	
	Create Clustered Index FactTertSold on #sold (factura,tert)
--select 'dupa sold din fFacturi',GETDATE()
--select '#sold',* from #sold --where factura like '1895%'

/*
	--pt factimpl
	insert into #sold 
	select '' as contract, 'SI' as tip,d2.tert,d2.factura,sum(d2.valoare+d2.tva-d2.achitat) as sold, max(d2.data_scadentei) as data_scadentei,
		max(p.loc_de_munca) as loc_de_munca,'4427' as grupa,'CC' as gestiune
	from #documente d2 
		left join factimpl p on d2.subunitate = p.subunitate and d2.numar = p.factura and d2.data = p.data
		left join facturi f on f.Subunitate=p.Subunitate and f.Factura=p.Factura and f.Tert=p.Tert 
			and f.Data=p.Data and f.Tip=p.Tip and (abs(f.Valoare)>0.01 or ABS(f.TVA_22)>0.01)
	where charindex(d2.tip,@tipuri_facturare)<>0 and p.Cont_de_tert like '411%' 
		--and p.Cont_de_tert<>@cont_fact_penaliz 
	group by d2.tert,d2.factura
	having sum(d2.valoare+d2.tva)-sum(case when d2.data<=dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(d2.tert,'D',0),'1901-01-01'),@dataj) then d2.achitat else 0 end)>=0.01
*/	
--select 'dupa factimpl',GETDATE()
--select '#sold',* from #sold where factura like '1895%'

	-- calcul zile si sold pt. penalizare
	select d2.tert,d2.factura,d2.tip,d2.data,d2.numar,max(s.sold)+isnull(-sum(d1.achitat),0) as sold_pen,
		datediff(day,max(case when dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(d2.tert,'D',0),'1901-01-01'),@dataj)>isnull(d1.data,'1901-1-1') 
			and dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(d2.tert,'D',0),'1901-01-01'),@dataj)>s.data_scadentei then dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(d2.tert,'D',0),'1901-01-01'),@dataj)
			when isnull(d1.data,'1901-1-1')>s.data_scadentei then dateadd(day,1,d1.data) else dateadd(day,1,s.data_scadentei) end),d2.data)+1 as zile_pen ,
			max(rtrim(s.loc_de_munca)) as loc_de_munca
	into #date_pen
	from #incasari d2
		left join #incasari d1 on d1.tert=d2.tert and d1.factura=d2.factura and (d1.data<d2.data or d1.data=d2.data and d1.numar<d2.numar)
		inner join #sold s on d2.factura=s.factura and d2.tert=s.tert
	group by d2.tert,d2.factura,d2.tip,d2.data,d2.numar	
	having d2.data>=max(case when dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(d2.tert,'D',0),'1901-01-01'),@dataj)>isnull(d1.data,'1901-1-1') 
		and dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(d2.tert,'D',0),'1901-01-01'),@dataj)>s.data_scadentei then dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(d2.tert,'D',0),'1901-01-01'),@dataj) 
		when isnull(d1.data,'1901-1-1')>s.data_scadentei then dateadd(day,1,d1.data) else dateadd(day,1,s.data_scadentei) end)
	
	Create Clustered Index FactTertDate on #date_pen (factura,tert)	
		
--select 'dupa calcul zile pen',GETDATE()
--select '#date_pen1',* from #date_pen --where factura like '1895%'
	--calcularea penalizarilor la fiecare incasare
	insert into #date_pen
	select s.tert,s.factura,'NE' as tip,@datas,'', max(s.sold)+isnull(-sum(d1.achitat),0) as sold_pen,
		datediff(day,	-- daca avem penalizare nou 
		(case when max(ps.data_penalizare) is not null then dateadd(day,1,max(ps.data_penalizare)) when max(pf.data_penalizare) is not null then dateadd(day,1,max(pf.data_penalizare))
			else max(case when dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(s.tert,'D',0),'1901-01-01'),@dataj)>isnull(d1.data,'1901-1-1') 
			and dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(s.tert,'D',0),'1901-01-01'),@dataj)>s.data_scadentei then dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(s.tert,'D',0),'1901-01-01'),@dataj)
					when isnull(d1.data,'1901-1-1')>s.data_scadentei then dateadd(day,1,d1.data) else dateadd(day,1,s.data_scadentei) end) end),@datas)+1 as zile_pen, 
		max(rtrim(s.loc_de_munca)) as loc_de_munca
		from #incasari d1 
			right join #sold s on d1.factura=s.factura and d1.tert=s.tert 
			left join (select tert,factura_penalizata,max(data_penalizare) as data_penalizare from penalizarifact p where tip_doc_incasare='NE' and tip_penalizare='D' 
				group by tert,factura_penalizata) pf on pf.tert=s.tert and pf.factura_penalizata=s.factura
			left join (select tert,factura,max(data) as data_penalizare from #date_pen p group by tert,factura) ps on ps.tert=s.tert and ps.factura=s.factura
	--where d1.data >=@dataj	
	group by s.tert,s.factura 
	having max(s.sold)+isnull(-sum(d1.achitat),0)>0.1		-- penalizari la @datas (cu soldul final)
	order by s.tert,s.factura
--select 'dupa cal pen la incasare',GETDATE()
--select '#date_pen2',* from #date_pen --where factura like '1895%'

	-- luare date din contract 
	select max(s.tip) tip,s.tert,s.factura,max(d.tip) tipd,left(max(d.numar),8) numar,d.data,max(d.sold_pen)sold_pen,max(d.zile_pen)zile_pen,
		max(d.sold_pen*d.zile_pen*(case when isnumeric(e.camp_2)=1 then convert(float,e.camp_2) else 0.04 end)/100) s_p,max(isnull(c.scadenta,30)) scadenta,
		isnull(c.Contract_coresp,'') as contract_coresp,max(case when isnumeric(e.camp_2)=1 then convert(float,e.camp_2) else 0.04 end) as procent_penalizare,
		max(rtrim(s.loc_de_munca)) as loc_de_munca,
		RTRIM(isnull(c.Punct_livrare,'')) as punct_livrare
	into #p	
	from #date_pen d 
		inner join #sold s on d.tert=s.tert and d.factura=s.factura
		left join con c on c.Subunitate=@subunitate and c.tert=s.tert and c.contract=s.contract and c.Tip='BK'
		left join (select max(e.camp_2) as camp_2,contract,tert from extcon e where e.tip='BF' and e.numar_pozitie=1 group by contract,tert) e 
					on c.contract_coresp = e.contract and c.tert = e.tert
	where sold_pen>0 and zile_pen>0 --and d.sold_pen*d.zile_pen*(case when isnumeric(e.camp_2)=1 then convert(float,e.camp_2) else 0 end)/100>0.01
		and not exists (select 1 from penalizarifact pf where pf.factura_penalizata=s.factura and pf.tert=d.tert and pf.data_doc_incasare>=d.data 
			and left(pf.factura,2) in ('D#','SD'))
		group by s.tert,c.Punct_livrare,c.Contract_coresp ,s.factura,d.data
		order by s.tert,s.factura,d.data
--select 'dupa date din contract',GETDATE()

--select '#p', * from #p-- where factura like '1895%'
		--pt factimpl
/*	insert into #p
	select max(s.tip) tip,s.tert,s.factura,max(d.tip) tipd,left(max(d.numar),8) numar,d.data,max(d.sold_pen)sold_pen,max(d.zile_pen)zile_pen,
		max(d.sold_pen*d.zile_pen*0.04/100) s_p,30 scadenta,'',0.04,max(rtrim(s.loc_de_munca)) as loc_de_munca,'' as punct_livrare
	from #date_pen d 
		inner join #sold s on d.tert=s.tert and d.factura=s.factura
	where s.tip='SI' and sold_pen>0 and zile_pen>0 --and d.sold_pen*d.zile_pen*(case when isnumeric(e.camp_2)=1 then convert(float,e.camp_2) else 0 end)/100>0.01
		and not exists (select 1 from penalizarifact pf where pf.factura_penalizata=s.factura and pf.tert=d.tert and pf.data_doc_incasare>=d.data 
	and left(pf.factura,2) in ('D#','SD'))
		group by s.tert,s.factura,d.data
		order by s.tert,s.factura,d.data
*/
--select 'dupa factimpl 2',GETDATE()		
--select * from penalizarifact
-- completare penalizari:

	insert into penalizarifact(Tip, Tert, Factura, Factura_penalizata, Tip_doc_incasare, Nr_doc_incasare, Data_doc_incasare, Sold_penalizare, Data_penalizare, 
		Zile_penalizare, Suma_penalizare, Valuta_penalizare,tip_penalizare,Stare,valid,contract_coresp,procent_penalizare,loc_de_munca,factura_generata,data_factura_generata,punct_livrare)
	select tip, tert, '' as factura, factura as factura_penalizata, tipd, numar, data, sold_pen, @datas as data_incasare, zile_pen, s_p,'' as valuta,
		'D','P',1,d.contract_coresp,d.procent_penalizare,d.loc_de_munca,null,null,isnull(rtrim(d.punct_livrare),'')
	from #p d 
	where not exists (select 1 from penalizarifact pf where pf.factura_penalizata=d.factura and pf.tert=d.tert and pf.tip=d.tip and d.tipd=pf.tip_doc_incasare 
		and pf.nr_doc_incasare=d.numar and pf.data_doc_incasare>=d.data and left(pf.factura,2) in ('D#','SD'))
--select 'dupa insert in penalizfa',GETDATE()

	--pentru terti cu X se invalideaza calculele
	update p set valid=0
	from penalizarifact p
		inner join facturi f on f.subunitate='1' and f.factura=p.factura_penalizata and f.tert=p.tert and f.cont_de_tert like '4118%'
		inner join infotert t on t.Subunitate='1' and p.tert = t.tert  and t.Identificator='' and t.Observatii in  ('X','D') 
	where p.Data_penalizare=@datas	
	
	--se invalideaza calculele <0.1
	update p set valid=0
	from penalizarifact p	
		outer apply (select sum(f.Suma_penalizare) as sumaTert from penalizarifact f where p.Tert=f.Tert and p.Data_penalizare=f.Data_penalizare) s	
	where p.Data_penalizare=@datas	
		and Suma_penalizare<=0.01
		and s.sumaTert<=0.01
				

	if @compatibilitateInUrma=0
	begin
		-- numar de factura temporar:
		declare @off_pdiez int
		select @off_pdiez=max(replace(factura,'D#','')) from penalizarifact where left(factura,2)='D#'
		set @off_pdiez=isnull(@off_pdiez,0)

		update penalizarifact set factura='D#'+convert(varchar(6),p.numar) from 
			(select p.tert,s.loc_de_munca,@off_pdiez+row_number() over (order by p.tert) as numar from penalizarifact p inner join #sold s on p.factura_penalizata=s.factura and p.tert=s.tert
				where p.factura='' group by p.tert,s.loc_de_munca) 
				p where p.tert=penalizarifact.tert and penalizarifact.factura='' and 
				exists (select 1 from #sold s where s.tert=p.tert and s.loc_de_munca=p.loc_de_munca and 
							s.factura=penalizarifact.factura_penalizata and s.tert=penalizarifact.tert)
	end
	else
	begin
		update penalizarifact set factura='D#'+convert(varchar(6),p.numar) from 
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
			@cod,'2011-10-31',max(s.gestiune),1, sum(suma_penalizare), 0,0,sum(suma_penalizare),sum(suma_penalizare),0,0, 'ASiS', 
			convert(datetime, convert(char(10), getdate(), 104), 104),replace(convert(char(8),getdate(), 108), ':', ''),
			'APBK',@cont_de_stoc,@cont_fact_penaliz,0,0,'V','','2011-10-31',1,
			s.loc_de_munca,@comanda,'Dobanzi','',@cont_de_stoc,0,p.tert,max(p.factura),'','',5,max(s.grupa),
			@cont_fact_penaliz,'',0,'2011-10-31','2011-10-31'
			,2,0,0,0,max(s.contract),''
		from penalizarifact p inner join #sold s on p.factura_penalizata=s.factura and p.tert=s.tert
		where p.data_penalizare=@datas  and left(p.factura,2)='D#' and not exists (select 1 from pozdoc pf where left(pf.numar,2)='D#')
		group by p.tert,s.loc_de_munca
	end	
	--stergere temporare

	drop table #date_pen drop table #documente drop table #incasari drop table #sold drop table #p

	if exists (select 1 from sysobjects where [type]='P' and [name]='calcdobSP')
		exec calcdobSP @dataj=@dataj,@datas=@datas,@tert=@tert

end try
begin catch
	set @mesaj=ERROR_MESSAGE()
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)



