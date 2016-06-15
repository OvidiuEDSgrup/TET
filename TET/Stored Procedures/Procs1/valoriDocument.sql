/*Pentru calcul valori document (antet documente). Prrocedura va primi o tabela #valdoc populata cu numere de documente si va calcul valorile lor. */
/*	Exemplu de apel
	if object_id ('tempdb..#valdoc') is not null drop table #valdoc
	Create table #valdoc (Subunitate varchar(9))
	exec valoriDocument_tabela
	insert into #valdoc (Subunitate, Tip, Numar, Data, Valoare, Tva_11, Tva_22, Valoare_valuta, Numar_pozitii)
	select '1', 'RM', '41888', '10/31/2014', 0, 0, 0, 0, 0
	exec valoriDocument
	select * from #valdoc
*/
Create procedure valoriDocument
as
begin try

-------------	din tabela par (parametri trimisi de Magic):
	declare @datapcons int, @rotunj_n int, @rotunjr_n int, @comppret int, @discInvers int, @mesaj varchar(1000)
	set @datapcons=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='DATAPCONS'),0)
	set @rotunj_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='ROTUNJ' and val_logica=1),2)
	set @rotunjr_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='ROTUNJR' and val_logica=1),2)
	set @comppret=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='COMPPRET'),0)
	set @discInvers=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='INVDISCAP'),0)

-------------	completare valori in tabela temporara
	update #valdoc 
	set Cont_corespondent=g.Cont_corespondent, Cont_venituri=g.Cont_venituri, 
		Cantitate=g.cantitate, Valoare=g.Valoare, Tva_22=g.Tva_22, Tva_11=g.Tva_11, Valoare_valuta=g.Valoare_valuta, Valoare_valuta_tert=g.Valoare_valuta_tert, 
		valoare_pret_amanunt=g.valoare_pret_amanunt, numar_pozitii=g.numar_pozitii
	from (select p.subunitate, p.tip as tip, p.numar, max(p.data) as data, 
		max(p.Cont_corespondent) as Cont_corespondent, max(p.Cont_venituri) as Cont_venituri,
		sum((case when p.tip_miscare='V' then 0 else p.Cantitate end)) as cantitate, 
		sum((case 
			when p.Tip in ('AP','AC','AS') then round(convert(decimal(17,5),p.Cantitate*p.Pret_vanzare),@rotunj_n) 
			when p.Tip in ('RM','RS') then round(convert(decimal(17,5),p.Cantitate*p.Pret_de_stoc),@rotunjr_n) 
			else round(convert(decimal(17,5),p.Cantitate*p.Pret_de_stoc), 2) end)
		-(case when p.Tip in ('RM','RS') and p.Procent_vama=3 and abs(p.Cantitate*p.Pret_de_stoc)>=0.01 then p.Tva_deductibil else 0 end))
		+ max(isnull(dvi.suma_suprataxe,0)) as valoare, 
		sum(case when left(p.Tip,1) in ('A','R') and p.tip<>'AI' and dvi.numar_DVI is null 
			and p.Cota_tva in (9,11) then round(convert(decimal(17,5), p.TVA_deductibil), 2) else 0 end) as Tva_11, 
		sum(case when left(p.Tip,1) in ('A','R') and p.tip<>'AI' and dvi.numar_DVI is null 
			and p.Cota_tva not in (0, 9, 11) then round(convert(decimal(17,5), p.TVA_deductibil), 2) else 0 end)
		--	Adaugat TVA de pe DVI:
		--	Pare ca nu trebuie citita valoarea din TVA_comis (nu se salveaza valoare TVA in el, nici in Ria nici in Plus, ci doar tipul de operatiune dinspre CGplus daca setarea [X]Importuri temporare si DVE)
			+max(isnull(dvi.tva_CIF+dvi.tva_22+0/*dvi.tva_comis*/,0)) as Tva_22,	
		(case when max(p.Valuta)<>'' then 
			-- receptii:
			(case when left(max(p.tip), 1)='R' then 
				(case when max(dvi.numar_DVI) is not null then sum(round(convert(decimal(17,5), p.cantitate*p.pret_valuta), 2)) 
					else sum(round(convert(decimal(17,5), p.cantitate*p.pret_valuta*(1+p.discount/100)), 2)	
					+(case when p.curs>0 and not(p.tip in ('RM','RS') and p.numar_DVI='' and p.procent_vama=1) 
						then (case when isnumeric(p.grupa)=1 then convert(float,p.grupa) else round(convert(decimal(17,5),p.TVA_deductibil/p.curs),2) end) else 0 end)) end)
		-- avize:
			else sum(round(convert(decimal(17,5), p.cantitate*p.pret_valuta*(1-(case when @discInvers=1 then (1-100/(100+p.discount))*100 else p.discount end)/100) 
				+ (case when @comppret=1 then p.cantitate*p.suprataxe_vama/1000 else 0 end)), 2)) 
				+ sum(round(convert(decimal(17,5),(case when p.curs>0 then p.TVA_deductibil/p.curs else 0 end)),2)) end) 
			else 0 end)
		-- adaugat valori de pe DVI:
		+ (case when max(dvi.numar_DVI) is not null and max(isnull(dvi.valuta_CIF, ''))=max(p.valuta) then max(isnull(dvi.valoare_CIF, 0)) else 0 end) as Valoare_valuta, 
		(case when max(p.Valuta)<>'' then sum(round(convert(decimal(17,5), p.cantitate*p.pret_valuta), 2))+ sum(round(convert(decimal(17,5),(case when p.curs>0 and p.procent_vama<>1 then p.TVA_deductibil/p.curs else 0 end)),2)) else 0 end) as Valoare_valuta_tert,
		sum(round(convert(decimal(17,5),p.cantitate*p.Pret_cu_amanuntul),2)) as valoare_pret_amanunt,
		count(1) as numar_pozitii
		from pozdoc p
		left outer join dvi on p.tip='RM' and dvi.subunitate=p.subunitate and dvi.numar_receptie=p.numar and dvi.data_DVI=p.data 
		inner join #valdoc d on p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Numar=d.Numar and p.Data=d.Data
		group by p.subunitate, p.tip, p.numar, p.data) g
	where #valdoc.Subunitate=g.subunitate and #valdoc.Tip=g.Tip and #valdoc.Numar=g.Numar and #valdoc.Data=g.Data 
		and not(#valdoc.Tip='CM' and @datapcons=1)	-- nu calculam aici pentru consumuri cu data in pozitii. Se calculeaza mai jos.

	/*	Adaugare la valoare document, valoare prestari. */
	if exists (select 1 from #valdoc where tip in ('RM','RS'))
	begin
		update #valdoc set #valdoc.Tva_11=#valdoc.Tva_11+g.Tva_11, #valdoc.Tva_22=#valdoc.Tva_22+g.Tva_22, #valdoc.Valoare_valuta=#valdoc.Valoare_valuta+g.Valoare_valuta
		from (select p.subunitate, d.tip, p.numar, p.data, 
			sum(isnull((case when dvi.numar_DVI is null and p.Cota_tva in (9,11) then round(convert(decimal(17,5), p.TVA_deductibil), 2) else 0 end),0)) as Tva_11,
			sum(isnull((case when dvi.numar_DVI is null and p.Cota_tva not in (0, 9, 11) then round(convert(decimal(17,5), p.TVA_deductibil), 2) else 0 end),0)) as Tva_22,
			sum(round(convert(decimal(17,5), p.cantitate*p.pret_de_stoc*(1+p.discount/100)), 2)
				+(case when p.Valuta<>'' and p.curs>0 and p.procent_vama<>1 then (case when isnumeric(p.grupa)=1 then convert(float,p.grupa) else round(convert(decimal(17,5),p.TVA_deductibil/p.curs),2) end) else 0 end)) 
			as Valoare_valuta
		from pozdoc p
			inner join #valdoc d on p.Subunitate=d.Subunitate and d.tip in ('RM','RS') and p.Numar=d.Numar and p.Data=d.Data
			left outer join dvi on d.tip='RM' and dvi.subunitate=p.subunitate and dvi.numar_receptie=p.numar and dvi.data_DVI=p.data 
		where p.tip='RP'
		group by p.subunitate, d.tip, p.numar, p.data) g 
		where #valdoc.Subunitate=g.Subunitate and #valdoc.Tip=g.Tip and #valdoc.Numar=g.Numar and #valdoc.Data=g.Data
	end

	/*	Calcul valori document pentru cazul in care se lucreaza cu data in pozitii consumuri.	*/
	if @datapcons=1 and exists (select 1 from #valdoc where tip='CM')
	begin
		update #valdoc set Cont_corespondent=g.Cont_corespondent, Cont_venituri=g.Cont_venituri, 
			cantitate=g.cantitate, valoare=g.valoare, numar_pozitii=g.numar_pozitii
		from (select p.subunitate, p.tip, p.numar, max(p.data) as data, max(p.Cont_corespondent) as Cont_corespondent, max(p.Cont_venituri) as Cont_venituri,
			sum(p.Cantitate) as cantitate, sum(round(convert(decimal(17,5),p.Cantitate*p.Pret_de_stoc), 2)) as valoare, count(1) as numar_pozitii
			from pozdoc p
			inner join #valdoc d on p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Numar=d.Numar 
				and d.tip='CM' and p.Data between dateadd(day, 1-day(d.Data), d.Data) and dateadd(day, -1, dateadd(month, 1, dateadd(day, 1-day(d.data), d.data)))
			group by p.subunitate, p.tip, p.numar, dateadd(day, -1, dateadd(month, 1, dateadd(day, 1-day(p.data), p.data)))) g
		where #valdoc.Subunitate=g.subunitate and #valdoc.Tip=g.Tip and #valdoc.Numar=g.Numar
			and #valdoc.Data between dateadd(day, 1-day(g.Data), g.Data) and dateadd(day, -1, dateadd(month, 1, dateadd(day, 1-day(g.Data), g.Data)))
	end

end try
begin catch
	set @mesaj =ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj,11,1)
end catch