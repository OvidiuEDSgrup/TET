--***
create procedure calcpen (@dataj datetime,@datas datetime,@tert varchar(13),@compatibilitateInUrma int=0)
as     

declare @data_ucc datetime,@cod varchar(20), @cont_fact_penaliz varchar(20), @comanda varchar(20), @cont_de_stoc varchar(20),
	@subunitate varchar(9),@utilizator varchar(13)	,@indbug varchar(20),@mesaj varchar(200)
begin try 		
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	
	exec luare_date_par 'UC', 'CODPEN', 0, 0, @cod output
	if ISNULL(@cod,'')=''
		set @cod='9500'	

	exec luare_date_par 'UC', 'CONTPEN', 0, 0, @cont_fact_penaliz output
	if ISNULL(@cont_fact_penaliz,'')=''
		set @cont_fact_penaliz='411125' 
		
	exec luare_date_par 'UC', 'INDBUGPEN', 0, 0, @indbug output
	if ISNULL(@indbug,'')=''
		set @indbug='1 0 0133205001'
			
	set @comanda=space(20)+@indbug
	set @cont_de_stoc=isnull((select max(cont) from nomencl where cod=@cod), '70851')

	if @tert='' 
		set @tert= null
	
	declare @tipuri_facturare varchar(100),@tipuri_incasare varchar(100) , @grupePenDob varchar(500)
	set @tipuri_facturare='AP,AS' set @tipuri_incasare='IB,C3,CO,CB,BX'
	set @grupePenDob='100.10.14,100.10.15,100.10.2,100.10.3'
	set @data_ucc=@dataj
	
	select * into #grupePenDob from dbo.fsplit(@grupePenDob,',')
	
	--preluare documente necesare din fFacturi
	select ft.* into #fFacturi 
	from fFacturi('B',null,@datas,@tert ,null,null,null,null,0, null, null) ft 
	where (dateadd(day,120,ft.data_scadentei)>=dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(ft.tert,'P',0),'1901-01-01'),@dataj)or tip='BX')
		and charindex(left(ft.tip,2),@tipuri_incasare+','+@tipuri_facturare)<>0--(si incasari si facturi)
		and ft.cod<>@cod--nu se calculeaza penalitati la penalitati
		and abs(ft.valoare)>=0 and abs(ft.tva)>=0		
--select '#fFacturi',* from #fFacturi where factura like '1300310%'
	
	--sterg facturile care au data scadentei dupa 1.07.2013
	delete from #fFacturi where data_scadentei>='2013-07-01' and charindex(left(tip,2),@tipuri_facturare)<>0 	
	
	select ft.* into #documente
	from #fFacturi ft			
		--inner join infotert t on ft.tert = t.tert and ft.subunitate=t.subunitate and t.identificator='' and t.Observatii not in ('X','P')--nu sunt terti exceptati de la calculul penalitatilor 
		left join nomencl n on n.Cod=ft.cod
	where ft.subunitate=@subunitate
		and not exists (select 1 from penalizarifact p where p.tert=ft.tert and p.data_factura_generata=ft.data_facturii and p.factura_generata=ft.factura)	
		and ((rtrim(ltrim(n.Grupa)) not in (select string from #grupePenDob)) or ISNULL(ft.cod,'')='')					 
--select '#documente',* from #documente where factura like '1300310%'

	-- incasari din fFacturi
	select d2.tert,d2.factura,d2.tip,isnull((case when d3.data_document='1901-01-01'then null else d3.data_document end),d2.data) data,d2.numar,sum(d2.achitat) as achitat 
	into #incasari 
	from #documente d2 
		left join (select tip, numar, data, data_document, cont,numar_pozitie from extpozplin) d3
			on /*d3.tip=d2.tip and*/ d3.numar=d2.numar and d3.data=d2.data /*and d3.cont=d2.cont_coresp*/ and d3.numar_pozitie=d2.numar_pozitie 
	where charindex(left(d2.tip,2),@tipuri_incasare)<>0 --numai incasarile
		and datediff(day,(select max(data_scadentei) from #documente where tip in ('AP','AS') and tert=d2.tert and factura=d2.factura),isnull((case when d3.data_document='1901-01-01'then null else d3.data_document end),d2.data))>30
			--diferenta dintre data scadentei si data incasarii este mai mare de 30 de zile 
		and datediff(day,(select max(data_scadentei) from #documente where tip in ('AP','AS') and tert=d2.tert and factura=d2.factura),isnull((case when d3.data_document='1901-01-01'then null else d3.data_document end),d2.data))<=90
			 --diferenta dintre data scadentei si data incasarii este mai mica de 90 de zile
		and isnull((case when d3.data_document='1901-01-01'then null else d3.data_document end),d2.data)<=@datas--incasarea s-a facut inainte de data actualului calcul de penalitati 
		and isnull((case when d3.data_document='1901-01-01'then null else d3.data_document end),d2.data)>dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(d2.tert,'P',0),'1901-01-01'),dateadd(day,-1,@dataj))--incasarea s-a facut dupa ultimul calcul de penalitati 
	group by d2.tert,d2.factura,d2.tip,isnull((case when d3.data_document='1901-01-01'then null else d3.data_document end),d2.data),d2.numar

--select '#incasari', * from #incasari where factura like '1300310%'

	-- sold pe facturi din fFacturifFacturi
	select max(isnull(p.contract,'')) as contract, max(d2.tip) as tip,d2.tert,d2.factura, round(sum(d2.valoare+d2.tva),2)-max(round(isnull(i.achitat,0),2)) as sold, 
		max(d2.data_scadentei) as data_scadentei, max(p.loc_de_munca) as loc_de_munca,max(p.grupa) as grupa,max(p.gestiune) as gestiune 
	into #sold 
	from #documente d2 
		left join pozdoc p on d2.subunitate = p.subunitate and d2.tip = p.tip and d2.numar = p.numar and d2.data = p.data and d2.numar_pozitie = p.numar_pozitie
		left join (select d.tert,d.factura,sum(d.achitat) as achitat
			from #documente d 
				left join (select tip, numar, data, data_document, cont, cont_corespondent, numar_pozitie from extpozplin) e
					on /*e.tip=d.tip and */e.numar=d.numar and e.data=d.data and e.cont=d.cont_coresp /*and e.cont_corespondent=d.cont_de_tert*/ 
						and e.numar_pozitie=d.numar_pozitie 
					where charindex(left(d.tip,2),@tipuri_incasare)<>0 --incasari
						and datediff(day,(select max(data_scadentei) from #documente where tip in ('AS','AP') and tert=d.tert and factura=d.factura),isnull((case when e.data_document='1901-01-01'then null else e.data_document end),d.data))<=90 --(de ce??)
					group by d.tert,d.factura) i --ce s-a achitat pe factura
			on i.tert=d2.tert and i.factura=d2.factura
	where isnull(p.stare,0) not in (4,6) 
		and charindex(d2.tip,@tipuri_facturare)<>0 --numai facturi
		and datediff(day,d2.data_scadentei,@datas)>90--au trecut peste 90 de zile de la data scadentei
		and datediff(day,d2.data_scadentei,dbo.data_maxima(isnull(dbo.data_ultimului_calcul_pen(d2.tert,'P',0),'1901-01-01'),@dataj))<=90
			--nu trecusera 90 de zile de la data scadentei pana la data ultimului calcul de penalitati
	group by d2.tert,d2.factura 
	having round(sum(d2.valoare+d2.tva),2)-max(round(isnull(i.achitat,0),2))>0 --soldul ramas pt calculul penalitatilor este mai mare de 0
	order by d2.tert,d2.factura
--sp_help pozdoc
--select '#sold' ,* from #sold where factura like '1300310%'
	
	--calculare penalizare la incasari
	select d2.tert,d2.factura,d2.tip,d2.data,d2.numar,d2.achitat as sold_pen,
		datediff(day,(select dateadd(day,1,max(data_scadentei)) from #documente where tip in ('AP','AS') and tert=d2.tert and factura=d2.factura),d2.data) as zile_pen 
	into #date_pen 
	from #incasari d2 
	group by d2.tert,d2.factura,d2.tip,d2.data,d2.numar,d2.achitat

--select '#date_pen',* from #date_pen where factura like '1300310%'
	
	--calculare penalizare la sold
	insert into #date_pen 
	select s.tert,s.factura,'NE' as tip,@datas,'', max(s.sold) as sold_pen,91/*???? datediff(day,d2.data_scadentei,@datas)*/ as zile_pen 
	from #sold s 
	group by s.tert,s.factura 
	order by s.tert,s.factura

--select '#date_pen',* from #date_pen where factura like '1300310%'

	--luare date din contract 
	select max(d.tip) as tip,d.tert,d.factura,max(d.tip) tipd,left(max(d.numar),8) numar,d.data,max(d.sold_pen)sold_pen,max(d.zile_pen)zile_pen,
		max(d.sold_pen*(case when d.tip='NE' then 15/*???*/ else 5/*???*/ end)/100) as s_p ,
		max((case when d.tip='NE' then 15/*???*/ else 5/*???*/ end)) as procent_penalizare
	into #p 
	from #date_pen d 
	where sold_pen>0 and zile_pen>0 --and d.sold_pen*(case when d.tip='NE' then 15 /*???*/ else 5/*???*/ end)/100>1 
		and not exists (select 1 from penalizarifact pf where pf.factura_penalizata=d.factura and pf.tert=d.tert and pf.data_doc_incasare>=d.data and left(pf.factura,2) in ('P#','SP')) 
	group by d.tert,d.factura,d.numar,d.data 
	order by d.tert,d.factura,d.numar,d.data
--select '#p', * from #p	where factura like '1300310%'


	declare @off_pdiez int
	if @compatibilitateInUrma=0
	begin
		-- completare penalizari:
		--select * from penalizarifact
		insert into penalizarifact(Tip, Tert, Factura, Factura_penalizata, Tip_doc_incasare, Nr_doc_incasare, Data_doc_incasare, Sold_penalizare, 
			Data_penalizare, Zile_penalizare, Suma_penalizare, Valuta_penalizare,tip_penalizare,stare,valid,contract_coresp,procent_penalizare,
			loc_de_munca,factura_generata,data_factura_generata,punct_livrare)
		select d.tip, d.tert, '' as factura, d.factura as factura_penalizata, d.tipd, d.numar, d.data, d.sold_pen, @datas as data_incasare, d.zile_pen,
			 d.s_p,'' as valuta,'P','P',1,rtrim(isnull((isnull(c.Contract_coresp,c1.contract)),'')),d.procent_penalizare,rtrim(c1.Loc_de_munca),
			 null,null,isnull(rtrim(c1.Punct_livrare),'')
		from #p d 
			outer apply (select top 1 k.Subunitate,k.tip,k.Factura,k.data,k.Data_facturii, k.Cod_tert, k.Contractul from doc k  
				where k.Subunitate=@subunitate and d.factura=k.factura and d.tert=k.cod_tert and k.tip in ('AP','AS') order by data)s 	
			left join con c on c.subunitate=@subunitate and c.Tip='BK' and s.Contractul =c.Contract and d.Tert=c.Tert 
			left join con c1 on c.subunitate=@subunitate and c1.Tip='BF' and s.Contractul=c1.Contract and d.Tert=c1.Tert 	
		where not exists (select 1 from penalizarifact pf where pf.factura_penalizata=d.factura and pf.tert=d.tert and pf.tip=d.tip 
			and d.tipd=pf.tip_doc_incasare and pf.nr_doc_incasare=d.numar and pf.data_doc_incasare>=d.data and left(pf.factura,2) in ('P#','SP'))

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
		
		-- numar de factura temporar:
		select @off_pdiez=max(replace(Factura,'P#','')) from penalizarifact where left(Factura,2)='P#'
		set @off_pdiez=isnull(@off_pdiez,0)
		update penalizarifact set factura='P#'+convert(varchar(6),p.numar),	loc_de_munca=rtrim(p.Loc_de_munca)
			from (select max(s.Contract) as contract, p.tert,s.loc_de_munca,@off_pdiez+row_number() over (order by p.tert) as numar 
				from penalizarifact p 
					inner join pozdoc s on p.factura_penalizata=s.factura and p.tert=s.tert
				where p.factura='' 
				group by p.tert,s.Contract,s.loc_de_munca)p 			
			where p.tert=penalizarifact.tert and penalizarifact.factura=''
				and	exists (select 1 from pozdoc s where s.tert=p.tert and s.loc_de_munca=p.loc_de_munca and s.factura=penalizarifact.factura_penalizata and s.tert=penalizarifact.tert)

	end
	else
	begin
		select @off_pdiez=max(replace(numar,'P#','')) from pozdoc where left(numar,2)='P#'
		set @off_pdiez=isnull(@off_pdiez,0)
		update penalizarifact set factura='P#'+convert(varchar(6),p.numar) 
			from(select p.tert,s.loc_de_munca,@off_pdiez+row_number() over (order by p.tert) as numar 
				from penalizarifact p 
					inner join pozdoc s on p.factura_penalizata=s.factura and p.tert=s.tert
				where p.factura='' 
				group by p.tert,s.loc_de_munca) p
				where p.tert=penalizarifact.tert and penalizarifact.factura='' 
					and	exists (select 1 from pozdoc s where s.tert=p.tert and s.loc_de_munca=p.loc_de_munca 
					and	s.factura=penalizarifact.factura_penalizata and s.tert=penalizarifact.tert)
		-- completare pozdoc:
		insert into pozdoc (Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos,
			Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
			Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator,Tip_miscare,Locatie, 
			Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, 
			Factura, Gestiune_primitoare, Numar_DVI, Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, 
			Data_scadentei, Procent_vama, Suprataxe_vama, Accize_cumparare, Accize_datorate, Contract, Jurnal)
		select @subunitate,'AS', max(p.factura),@cod,'2011-10-31',max(s.cod_gestiune),1, sum(suma_penalizare), 0,0,
			sum(suma_penalizare),sum(suma_penalizare),0,0, 'ASiS', convert(datetime, convert(char(10), getdate(), 104), 104),
			replace(convert(char(8),getdate(), 108), ':', ''),'APBK',@cont_de_stoc,@cont_fact_penaliz,0,0,'V','','2011-10-31',
			1,s.loc_munca,@comanda,'Penalitati','',@cont_de_stoc,0,p.tert,max(p.factura),'','',5,' '--max(pd.grupa)
			,@cont_fact_penaliz,'',0,'2011-10-31','2011-10-31',2,0,0,0,max(s.contractul),''
		from penalizarifact p inner join doc s on p.factura_penalizata=s.factura and p.tert=s.cod_tert
		where p.data_penalizare=@datas  and left(p.factura,2)='P#' 
			and not exists (select 1 from pozdoc where left(numar,2)='P#') 
			group by p.tert,s.loc_munca
	
	end
	
	if exists (select 1 from sysobjects where [type]='P' and [name]='calcpenSP')
		exec calcpenSP @dataj=@dataj,@datas=@datas,@tert=@tert
	
	drop table #date_pen 
	drop table #documente 
	drop table #incasari 
	drop table #sold 
	drop table #p	
end try
begin catch
	set @mesaj=ERROR_MESSAGE()
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
--select * from pozcon
