
create procedure RefacereDoc @dataj datetime, @datas datetime, @tip char(2)='', @numar char(20)=''
as
	declare 
		@sub char(9), @datapozCM int, @accimpDVI int, @compfixapret int, @ctcorantCM int, @DVE int, 
		@Begapam int, @Magellan int, @zecrotav int, @zecrotrec int, @discInvers int, @discsep int, @scriuValDoc int

	select 
		@sub=isnull((case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @sub end),''),
		@datapozCM=isnull((case when Parametru='DATAPCONS' then Val_logica else @datapozCM end),0),
		@accimpDVI=isnull((case when Parametru='ACCIMP' then Val_logica else @accimpDVI end),0),
		@compfixapret=isnull((case when Parametru='COMPPRET' then Val_logica else @compfixapret end),0),
		@ctcorantCM=isnull((case when Parametru='CCORANTCM' then Val_logica else @ctcorantCM end),0),
		@DVE=isnull((case when Parametru='DVE' then Val_logica else @DVE end),0),
		@Begapam=isnull((case when Parametru='BEGAPAM' then Val_logica else @Begapam end),0),
		@Magellan=isnull((case when Parametru='MAGELLAN' then Val_logica else @Magellan end),0),
		@zecrotav=isnull((case when Parametru='ROTUNJ' then Val_numerica else @zecrotav end),2),
		@zecrotrec=isnull((case when Parametru='ROTUNJR' then Val_numerica else @zecrotrec end),2),
		@discInvers=isnull((case when Parametru='INVDISCAP' then Val_logica else @discInvers end),0),
		@discsep=isnull((case when Parametru='DISCSEP' then Val_logica else @discsep end),0),
		@scriuValDoc=isnull((case when Parametru='VANTETDOC' then Val_logica else @scriuValDoc end),0)
	from par
	where 
		(Tip_parametru='GE' and Parametru in ('SUBPRO','MAGELLAN','BEGAPAM','ROTUNJ','ROTUNJR','DVE',
		'CCORANTCM','COMPPRET','ACCIMP','DATAPCONS','INVDISCAP','DISCSEP','VANTETDOC')) 

	update doc 
		set valoare=0, tva_11=0, tva_22=0, valoare_valuta=0, numar_pozitii=0 
	where doc.subunitate=@sub and (RTrim(@tip)='' or doc.tip=@tip) and (RTrim(@numar)='' or doc.numar=@numar) and doc.data between @dataj and @datas 

	insert into doc 
		(Subunitate, Tip, Numar, Cod_gestiune, Data,Cod_tert, Factura, Contractul, Loc_munca, Comanda, Gestiune_primitoare, Valuta, Curs, Valoare, Tva_11, 
		Tva_22, Valoare_valuta, Cota_TVA, Discount_p, Discount_suma, Pro_forma,Tip_miscare, Numar_DVI, Cont_factura, Data_facturii, Data_scadentei, Jurnal, Numar_pozitii, Stare) 
	select 
		p.subunitate, p.tip, p.numar, max(p.gestiune), min(p.data), '', '', '', '', '', '', '', 0,	0, 0, 0, 0, 0, 0, 0, 0, 
		max(case when p.tip in ('AP', 'AS') and left(p.grupa, 4)='4428' then '8' when @compfixapret=0 and p.tip='AP' and p.suprataxe_vama=1 then 'R' else '' end), 
		(case when @DVE=1 and p.tip='AP' and max(p.valuta)<>'' and max(isnull(it.zile_inc, 0))=2 then max(p.barcod) 
			 when p.tip in ('RM', 'RS') and max(b.numar_DVI) is not null then max(p.numar_DVI) 
		 else '' end), '', '01/01/1901', '01/01/1901', '', 0, max(p.stare) 
	from pozdoc p 
	left outer join dvi b on p.tip='RM' and b.subunitate=p.subunitate and b.numar_receptie=p.numar and b.data_DVI=p.data 
	left outer join terti t on t.subunitate=p.subunitate and t.tert=p.tert 
	left outer join infotert it on it.subunitate=p.subunitate and it.tert=p.tert and it.identificator=''
	where p.subunitate=@sub and (RTrim(@tip)='' or p.tip=@tip) and (RTrim(@numar)='' or p.numar=@numar) and p.data between @dataj and @datas 
	group by p.subunitate, p.tip, p.numar, year(p.data), month(p.data), (case when not (@datapozCM=1 and p.tip='CM') then p.data else '01/01/1901' end)
	having not exists (select 1 from doc dd where dd.subunitate=p.subunitate and dd.tip=p.tip and dd.numar=p.numar and dd.data=min(p.data)) 

	select p.subunitate, p.tip, p.numar, min(p.data) as data, 
	max(p.gestiune) as cod_gestiune, min(case when p.gestiune=isnull(d.cod_gestiune,'') then 0 else 1 end) as inloc_gest,
	max(p.tert) as cod_tert, min(case when p.tert=isnull(d.cod_tert,'') then 0 else 1 end) as inloc_tert,
	max(p.factura) as factura, min(case when p.factura=isnull(d.factura,'') then 0 else 1 end) as inloc_factura,
	max(p.contract) as contractul, 
	max(p.loc_de_munca) as loc_munca, min(case when p.loc_de_munca=isnull(d.loc_munca,'') then 0 else 1 end) as inloc_loc_munca,
	max(p.comanda) as comanda, min(case when p.comanda=isnull(d.comanda,'') then 0 else 1 end) as inloc_comanda,
	max(case when @ctcorantCM=1 and p.tip='CM' then p.cont_corespondent when p.tip in('RM', 'RS') then p.cont_venituri 
	 when p.tip in ('AC', 'AP', 'AS') then (case when @Begapam=1 or @Magellan=1 then left(p.numar_dvi, 13) else substring(p.numar_dvi, 14, 5) end) 
	 when p.tip='AE' then p.grupa
	 else left(p.gestiune_primitoare,13) end) as gestiune_primitoare, 
	max(p.valuta) as valuta, max(p.curs) as curs, 
	/*	Aici incepe partea de calculul valori pentru antet documente. S-a stabilit cu Ghita sa se scrie in tabela doc in baza unui parametru (VANTETDOC) de compatibilitate in urma. */
	sum(case when p.tip in ('AC', 'AP', 'AS') 
	-- am schipat partea de mai jos (@discsep=1 and 1=0) cu Valoare TVA functie de discount intrucat nu e ok. Corect este ca Valoare fara TVA sa fie cantitate*pret_vanzare
	-- vom trata in inregAvize ca discountul sa se determine functie de cantitate * (pret_valuta-pret_vanzare).
	 then round(convert(decimal(17,5), p.cantitate*(case when @discsep=1 and 1=0 then p.Pret_valuta*(1-(case when @discInvers=1 then (1-100/(100+p.discount))*100 else p.discount end)/100)
		*(case when p.valuta<>'' and p.curs>0 then p.curs else 1 end) else p.pret_vanzare end)),@zecrotav) 
	 else round(convert(decimal(17,5), p.cantitate*(case when p.tip='RP' then p.pret_valuta*(case when p.valuta<>'' and p.curs>0 then p.curs else 1 end) 
	 else p.pret_de_stoc end)), (case when left(p.tip,1)='R' then @zecrotrec else 2 end))-
	(case when p.tip in ('RM','RS') and p.Procent_vama=3 and abs(p.cantitate*p.pret_de_stoc)>=0.01 then p.TVA_deductibil else 0 end) end) + max(isnull(b.suma_suprataxe, 0)) as valoare, 
	(case when left(p.tip, 1) in ('A', 'R') and p.tip<>'AI' and max(b.numar_DVI) is null 
	 then sum((case when p.cota_TVA in (9, 11) then round(convert(decimal(17,5), p.TVA_deductibil), 2) else 0 end)) else 0 end) as tva_11, 
	(case when left(p.tip, 1) in ('A', 'R') and p.tip<>'AI' and max(b.numar_DVI) is null 
	 then sum((case when p.cota_TVA not in (0, 9, 11) then round(convert(decimal(17,5), p.TVA_deductibil), 2) else 0 end)) else 0 end) 
	+ round(convert(decimal(17,5), max(isnull(b.TVA_CIF, 0)+isnull(b.TVA_22, 0))), 2) as tva_22, 
	(case when max(p.valuta)<>'' then 
		-- receptii:
		(case when left(p.tip, 1)='R' then (case when max(b.numar_DVI) is not null then sum(round(convert(decimal(17,5), p.cantitate*p.pret_valuta), 2)) 
			else sum(round(convert(decimal(17,5), p.cantitate*(case when p.tip='RP' then p.pret_de_stoc else p.pret_valuta end)*(1+p.discount/100)), 2)	
				+(case when p.curs>0 and not(p.tip='RM' and p.numar_DVI='' and p.procent_vama=1) then (case when isnumeric(p.grupa)=1 then convert(float,p.grupa) else round(convert(decimal(17,5),p.TVA_deductibil/p.curs),2) end) else 0 end)) end)
		-- avize:
		else sum(round(convert(decimal(17,5), p.cantitate*p.pret_valuta*(1-(case when @discInvers=1 then (1-100/(100+p.discount))*100 else p.discount end)/100) + (case when @compfixapret=1 then p.cantitate*p.suprataxe_vama/1000 else 0 end)), 2)) 
		--Lucian 29.03.2013 -> am mutat aici rotunjirea la 2 zecimale pt. valoarea TVA-ului in valuta 
		--(inainte era in partea de SUM de mai sus, dar din cauza rotunjirii cumulate (baza+tva) nu era corelatie cu inregistrarile contabile unde se face rotunjire separat pt. baza si separat pt. TVA.
		+ sum(round(convert(decimal(17,5),(case when p.curs>0 then p.TVA_deductibil/p.curs else 0 end)),2)) end) 
	else 0 end) 
	-- de pe DVI:
	+ (case when max(b.numar_DVI) is not null and max(isnull(b.valuta_CIF, ''))=max(p.valuta) then max(isnull(b.valoare_CIF, 0)) else 0 end) as valoare_valuta, 
	/*	Pana aici este calculul valorilor din document.	*/
	(case when p.tip='RM' and max(p.numar_DVI)<>'' then 0 else max(p.procent_vama) end) as cota_tva, 
	(case when max(b.numar_DVI) is null then max(p.discount) else 0 end) as discount_p, 
	(case when p.tip in ('AP', 'AS', 'AC', 'TE') then max(p.accize_cumparare) when p.tip='PP' then max(p.accize_datorate) else 0 end) as discount_suma, 
	(case 
		when p.tip in ('AP', 'AS') and not (@DVE=1 and max(p.valuta)<>'' and max(isnull(it.zile_inc, 0))=2) then max(isnull(d.numar_DVI, ''))
		when p.tip in ('AP', 'AS', 'RS') or (p.tip='RM' and (max(isnull(g.tip_gestiune, '')) not in ('A', 'V') or @accimpDVI=0)) 
			then (case when p.tip in ('AP', 'AS') then max(p.barcod) else max(p.numar_DVI) end) 
		else '' end) as numar_dvi, 
	max(p.cont_factura) as cont_factura, 
	(case when max(p.data_facturii)>'01/01/1901' then max(p.data_facturii) else min(p.data) end) as data_facturii, 
	(case when max(p.data_scadentei)>'01/01/1901' then max(p.data_scadentei) else min(p.data) end) as data_scadentei, 
	max(p.jurnal) as jurnal, 
	sum(1) as numar_pozitii, 
	(case when max(case when p.stare=2 then 1 else 0 end)=1 then 2 else max(p.stare) end) as stare, 
	max(isnull(g.tip_gestiune, '')) as tip_gestiune 
	into #tmpdoc 
	from pozdoc p 
	left outer join dvi b on p.tip='RM' and b.subunitate=p.subunitate and b.numar_receptie=p.numar and b.data_DVI=p.data 
	left outer join gestiuni g on g.subunitate=p.subunitate and g.cod_gestiune=p.gestiune 
	left outer join doc d on p.subunitate=d.subunitate and p.tip=d.tip and p.numar=d.numar and p.data=d.data
	left outer join terti t on t.subunitate=p.subunitate and t.tert=p.tert
	left outer join infotert it on it.subunitate=p.subunitate and it.tert=p.tert and it.identificator=''
	where p.subunitate=@sub and (RTrim(@tip)='' or p.tip=@tip or @tip in ('RM','RS') and p.tip='RP') and (RTrim(@numar)='' or p.numar=@numar) and p.data between @dataj and @datas 
	group by p.subunitate, p.tip, p.numar, year(p.data), month(p.data), (case when not (@datapozCM=1 and p.tip='CM') then p.data else '01/01/1901' end), 
	(case when p.tip = 'RP' then p.gestiune_primitoare else '' end),(case when p.tip = 'RP' then p.valuta else '' end)

	update doc set 
		cod_gestiune=(case when inloc_gest=1 then td.cod_gestiune else doc.cod_gestiune end),
		cod_tert = (case when inloc_tert=1 then td.cod_tert else doc.cod_tert end),
		factura = (case when inloc_factura=1 then td.factura else doc.factura end), 
		contractul = td.contractul, 
		loc_munca = (case when inloc_loc_munca=1 then td.loc_munca else doc.loc_munca end), 
		comanda = (case when inloc_comanda=1 then td.comanda else doc.comanda end), 
		gestiune_primitoare = td.gestiune_primitoare, 
		valuta = (case when doc.valuta<>'' then doc.valuta else td.valuta end), 
		curs = (case when doc.valuta<>'' or td.valuta<>'' then td.curs else 0 end), 
		Cota_TVA = td.cota_tva, Discount_p = td.discount_p, Discount_suma = td.discount_suma, 
		Numar_DVI = (case when doc.tip in ('AP', 'AS', 'RS') or (doc.tip='RM' and (td.tip_gestiune not in ('A', 'V') or @accimpDVI=0)) then td.numar_dvi else doc.Numar_DVI end), 
		cont_factura = td.cont_factura, data_facturii = td.data_facturii, data_scadentei = td.data_scadentei, 
		jurnal = td.jurnal, 
		stare = (case when doc.stare=2 or td.stare=2 then 2 when doc.stare=6 or td.stare=6 then 6 else td.stare end)
	from #tmpdoc td
	where td.subunitate=doc.subunitate and td.tip=doc.tip and td.numar=doc.numar 
	and year(doc.data)=year(td.data) and month(doc.data)=month(td.data) and (@datapozCM=1 and doc.tip='CM' or doc.data=td.data) 

	/*	In baza parametrului de compatibilitate in urma scriem in tabela doc, valori document. Voi scrie cu dinamic SQL pentru optimizare. */
	if @scriuValDoc=1
	begin
		update doc set 
			doc.valoare = doc.valoare + td.valoare, 
			doc.Tva_11 = doc.tva_11 + td.tva_11, 
			doc.Tva_22 = doc.TVA_22 + td.tva_22 + isnull((select sum(tdp.tva_22) from #tmpdoc tdp where doc.tip in ('RM', 'RS') and tdp.subunitate=doc.subunitate and tdp.tip='RP' 
				and tdp.numar=doc.numar and tdp.data=doc.data and tdp.gestiune_primitoare = ''), 0),
			doc.Valoare_valuta = doc.valoare_valuta + td.valoare_valuta + isnull((select sum(tdp.valoare_valuta) from #tmpdoc tdp where doc.tip in ('RM', 'RS') and tdp.subunitate=doc.subunitate and tdp.tip='RP' 
				and tdp.numar=doc.numar and tdp.data=doc.data and tdp.gestiune_primitoare = '' and tdp.valuta=doc.valuta), 0),
			doc.numar_pozitii = doc.numar_pozitii + td.numar_pozitii
		from #tmpdoc td
		where td.subunitate=doc.subunitate and td.tip=doc.tip and td.numar=doc.numar 
			and year(doc.data)=year(td.data) and month(doc.data)=month(td.data) and (@datapozCM=1 and doc.tip='CM' or doc.data=td.data) 
	end

	drop table #tmpdoc 


