/***	Procedura pt Raport de gestiune pe baza celui de Magic - pt viteza, nu se foloseste soldconturi
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'raportGestiune') AND type in (N'P'))
DROP procedure raportGestiune
GO
--***
create procedure raportGestiune(--*/ declare
@datajos datetime,@datasus datetime, @gestiunea varchar(20),@tip_gestiune nvarchar(1), @soldc int=0
--/**
select @datajos='2014-05-27 00:00:00',@datasus='2014-05-27 00:00:00',@gestiunea='210.IS'
,@tip_gestiune=N'A'
--*/)as
set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
	------------------------ stergere eventuale tabele temporare
	if object_id('tempdb..#soldi') is not null drop table #soldi
	if object_id('tempdb..#rapg_Fgrupat') is not null drop table #rapg_Fgrupat
	if object_id('tempdb..#rapg_grupat') is not null drop table #rapg_grupat
	if object_id('tempdb..#rapg') is not null drop table #rapg
	
	/**	Pregatire filtrare pe proprietati utilizatori*/
	declare @fltGstUt int
	declare @GestUtiliz table(valoare varchar(200), cod varchar(20), analitic371 varchar(20), analitic707 varchar(20))
	insert into @GestUtiliz (valoare,cod, analitic371, analitic707)
	select valoare, cod_proprietate,
			'371'+'.'+rtrim(cod_proprietate)+'%' analitic371, '707'+'.'+rtrim(cod_proprietate)+'%' analitic707 from fPropUtiliz(null) where cod_proprietate='GESTIUNE' and valoare<>''
	set	@fltGstUt=isnull((select count(1) from @GestUtiliz),0)
		
	declare @q_datasus datetime,@q_datajos datetime,@q_gestiune_jos varchar(20),@q_gestiune_sus varchar(20),@q_tip_gestiune varchar(1)
	select @q_datasus=@datasus,@q_datajos=@datajos,@q_gestiune_jos=isnull(@gestiunea,''),@q_gestiune_sus=isnull(@gestiunea,'')+'zzzzzzzzz'
			,@q_tip_gestiune=@tip_gestiune

	declare @q_sub varchar(9), @q_data_inchisa datetime,
			@analitic371 varchar(20), @analitic707 varchar(20)--, @q_pret_am_fara_tva int, @q_totaluri_pe_corespondente int
	select @q_sub='1', @q_data_inchisa=dateadd(d,-1,dateadd(M,1,
			convert(datetime,convert(varchar(4),(select val_numerica from par where Tip_parametru='GE' and Parametru='anulinc'))+'-'+
						convert(varchar(2),(select val_numerica from par where Tip_parametru='GE' and Parametru='lunainc'))+'-1')
							))
	select @analitic371='371'+'.'+rtrim(@q_gestiune_jos)+'%', @analitic707='707'+'.'+rtrim(@q_gestiune_jos)+'%'
	/**	:9=	IF (Trim (Cu TVA)='Toate',0,IF (InStr (Cu TVA,'cu')>0,1,2))*/

	declare @incLuna datetime
	set @incLuna=dateadd(d,1-day(@q_datajos),@q_datajos)

	-----------------	rulaj valorice (V):
	select substring(cont_debitor,5,9) as gestiune, tip_document, numar_document, data, sum(suma) suma, 0 as sumaE, 
		max(explicatii) explicatii, 'V' as tip, 0 as val_cu_amanuntul
		--, 0 as discount, 0 as servicii,space(13) as coresp
	into #rapg 
	from pozincon  
	where @q_tip_gestiune='V' and subunitate=@q_sub and data between @incLuna and @q_datasus and cont_debitor like @analitic371 
		and tip_document<>'IC' and 
		exists(select 1 from gestiuni where subunitate=@q_sub and tip_gestiune='V' and substring(cont_debitor,5,9)=cod_gestiune)
		and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where cont_debitor like pr.analitic371))
	  group by substring(cont_debitor,5,9), tip_document, numar_document, data
	union all 
	select substring(cont_creditor,5,9), tip_document, numar_document, data, 0, sum(suma) suma, max(explicatii) explicatii, 'V', 0 
			--,/*(case when totaluri_pe_corespondente=0 then '' else cont_debitor end)*/ '', 0, 0
	from pozincon  
	where @q_tip_gestiune='V' and subunitate=@q_sub and data between @incLuna and @q_datasus and cont_creditor like @analitic371 and tip_document<>'IC' and 
		exists(select 1 from gestiuni where subunitate=@q_sub and tip_gestiune='V' and cod_gestiune=substring(cont_creditor,5,9))
		and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where Cont_creditor like pr.analitic371))
	  group by substring(Cont_creditor,5,9), tip_document, numar_document, data
	union all
	select substring(cont_corespondent,5,9), 'IN', numar, data, 0, 
			sum(suma) suma, max(explicatii) explicatii, 'V', 0
			--,'', 0, 0
	from pozplin 
	where @q_tip_gestiune='V' and subunitate=@q_sub and data between @incLuna and @q_datasus and cont_corespondent like @analitic707 and 
		exists(select 1 from gestiuni where subunitate=@q_sub and tip_gestiune='V' and substring(cont_corespondent,5,9)=cod_gestiune)
		and plata_incasare<>'ID'
		and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where Cont_corespondent like pr.analitic707))
	  group by substring(cont_corespondent,5,9), numar, data
	union all
	select substring(cont_cred,5,9), 'FB', numar_document, data, 0, 
			sum(suma) suma, max(explicatii) explicatii,'V', 0
			--,'', 0,  0
	from pozadoc 
	where @q_tip_gestiune='V' and subunitate=@q_sub and data between @incLuna and @q_datasus and cont_cred like @analitic707 and 
		exists(select 1 from gestiuni where subunitate=@q_sub and tip_gestiune='V' and substring(cont_cred,5,9)=cod_gestiune)
		and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where Cont_cred like pr.analitic707))
	  group by substring(cont_cred,5,9), numar_document, data
	union all
	select (case when p.tip='AP' then p.gestiune else substring(cont_venituri,5,9) end), p.tip, numar, data, 0, 
		sum(round(convert(decimal(17,5), cantitate*p.pret_vanzare*(1+0)), 2)+TVA_deductibil) suma, max(n.denumire) explicatii,
		'V', 0	--,'', 0, 0
	from pozdoc p left join nomencl n on p.cod=n.cod
	where @q_tip_gestiune='V' and p.subunitate=@q_sub and p.data between @incLuna and @q_datasus and p.cont_venituri like @analitic707 and (p.tip='AP' and 
		exists(select 1 from gestiuni where subunitate=@q_sub and tip_gestiune='V' and p.gestiune=cod_gestiune) or p.tip='AS' and 
		exists(select 1 from gestiuni where subunitate=@q_sub and tip_gestiune='V' and cod_gestiune=substring(cont_venituri,5,9)))
		and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where Cont_venituri like pr.analitic707))
	  group by (case when p.tip='AP' then p.gestiune else substring(p.cont_venituri,5,9) end), p.tip, p.numar, p.data
	----------------------------- rulaj cantitative/amanunt (C sau A):
	union all
	select gestiune, tip as tip_document, numar as numar_document, data, 
	sum(case when tip_miscare='I' then round(convert(decimal(17,5), cantitate*
			(case when @q_tip_gestiune='A' then pret_cu_amanuntul else Pret_de_stoc end)),2) else 0 end) as suma, 
	sum(case when tip_miscare='E' then round(convert(decimal(17,5), cantitate*
			(case when @q_tip_gestiune='A' then pret_amanunt_predator else Pret_de_stoc end)),2) else 0 end) as sumaE, 
	(case when tip='TE' then 'Gest. primitoare '+max(rtrim(p.Gestiune_primitoare)) else max(isnull(rtrim(t.denumire),'')) end) as explicatii, @q_tip_gestiune as tip, 
		sum(round(convert(decimal(17,5), cantitate*(case when @q_tip_gestiune='A' then pret_cu_amanuntul else Pret_de_stoc end)),2)) as val_cu_amanuntul
	/*,space(13) as coresp
			, avg(discount) discount,
		max(case when tip_miscare='V' then 1 else 0 end) as servicii*/
	from pozdoc p
		left join terti t on p.Tert=t.Tert and p.Subunitate=t.Subunitate
	where @q_tip_gestiune<>'V' and p.subunitate=@q_sub and data between @incLuna and @q_datasus and gestiune between @q_gestiune_jos and @q_gestiune_sus and 
			(tip_miscare in ('I','E','V') /*V pentru taxa verde*/ or left(cont_de_stoc,4)='4428') and exists 
			(select 1 from gestiuni where subunitate=@q_sub and tip_gestiune=@q_tip_gestiune and gestiune=cod_gestiune)
			and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=p.gestiune))
			/*and (:9=0 or :9=1 and TVA_neexigibil<>0 or :9=2 and TVA_neexigibil=0)*/
		group by tip, gestiune, numar, data
	union all
	select gestiune_primitoare, 'TI', numar, data, sum(round(convert(decimal(17,5), cantitate*
			(case when @q_tip_gestiune='A' then pret_cu_amanuntul else Pret_de_stoc end)),2)), 0, 'Gest. predatoare '+max(rtrim(p.Gestiune)), @q_tip_gestiune
			,sum(round(convert(decimal(17,5), cantitate*(case when @q_tip_gestiune='A' then pret_amanunt_predator else Pret_de_stoc end)),2))
	/*		,'', 
				0, 0*/
	from pozdoc p
	where @q_tip_gestiune<>'V' and subunitate=@q_sub and tip='TE' and data between @incLuna and @q_datasus and 
			gestiune_primitoare between @q_gestiune_jos and @q_gestiune_sus and 
			exists(select 1 from gestiuni where subunitate=@q_sub and tip_gestiune=@q_tip_gestiune and cod_gestiune=gestiune_primitoare)
			and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=p.Gestiune_primitoare))
			/*and (:9=0 or :9=1 and TVA_neexigibil<>0 or :9=2 and TVA_neexigibil=0)*/
	group by tip, gestiune_primitoare, numar, data
	
	select p.Cod,p.Cod_intrare,gestiune_primitoare, 'TI', numar, data, suma=(round(convert(decimal(17,5), cantitate*
			(case when @q_tip_gestiune='A' then pret_cu_amanuntul else Pret_de_stoc end)),2))--, 0, 'Gest. predatoare '+(rtrim(p.Gestiune)), @q_tip_gestiune
			,(case when @q_tip_gestiune='A' then 'pret_cu_amanuntul' else 'Pret_de_stoc' end)
			,val_cu_amanuntul=(round(convert(decimal(17,5), cantitate*(case when @q_tip_gestiune='A' then pret_amanunt_predator else Pret_de_stoc end)),2))
			,(case when @q_tip_gestiune='A' then 'pret_amanunt_predator' else 'Pret_de_stoc' end)
			,p.Pret_amanunt_predator,p.Pret_cu_amanuntul,p.Cantitate
	/*		,'', 
				0, 0*/
	from pozdoc p
	where @q_tip_gestiune<>'V' and subunitate=@q_sub and tip='TE' and data between @incLuna and @q_datasus and 
			gestiune_primitoare between @q_gestiune_jos and @q_gestiune_sus and 
			exists(select 1 from gestiuni where subunitate=@q_sub and tip_gestiune=@q_tip_gestiune and cod_gestiune=gestiune_primitoare)
			and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=p.Gestiune_primitoare))
			and p.Data='2014-05-27'
	order by tip,Numar,data,cod, Cod_intrare
	
	--SELECT * from pozdoc p join nomencl n on n.Cod=p.Cod 
	--where p.Tip='TE' and p.Numar='is100001' and p.Data='2014-05-27' 
	--and n.Tip='S'
	--select * from #rapg order by 1,2,3,4
	/*union all
	select subunitate, cod_gestiune, 'SI', '', @incLuna, 0, 0, 
	'', '', 0, @q_tip_gestiune, 0, 0
	from stocuri 
	where @q_tip_gestiune<>'V' and subunitate=@q_sub and (@q_gestiunea is null or cod_gestiune=@q_gestiunea)
	and exists (select 1 from gestiuni where subunitate=@q_sub and tip_gestiune=@q_tip_gestiune and cod_gestiune=cod_gestiune)
	and stoc_initial <> 0 */

	---------------- grupez aici rulajul, pentru viteza mai mare in continuare:

	select rtrim(r.gestiune) as gestiune, r.data, tip_document, numar_document, 
	sum(suma) suma, sum(sumaE) sumaE,
	0 rulaj, @q_tip_gestiune tip_gestiune,
	(case when tip='A' and tip_document in ('AP','AC','AS') then 'Valoare v.'+rtrim(convert(char(15),convert(decimal(12,2),sum(val_cu_amanuntul))))+
			(case when Tip_document='AC' and abs(sum(val_cu_amanuntul)-sum(sumaE))>0.01 
					then ' disc. '+rtrim(convert(char(15),convert(decimal(12,2),sum(sumaE)-sum(val_cu_amanuntul))))
					else '' end)
			else max(explicatii) end) as explicatii, --coresp, 
			(case when 0=1 then '01/01/2999' else r.data end) as data_ord, sum(val_cu_amanuntul) val_cu_amanuntul
	into #rapg_grupat
	from #rapg r
	group by tip, r.gestiune, tip_document, numar_document, r.data--, coresp

	--------------------- solduri initiale (din pozdoc de la ult. data inchisa pana ieri, din istoricstocuri pentru ult. data inchisa):

	select dateadd(d,2,@q_data_inchisa) as data, rtrim(substring(cont, 5,20)) as gestiune, f.suma_debit as si, 0 as apare	
			--> campul apare determina care solduri initiale se transmit in raport (apare=1) si care sunt doar pentru calcul (apare=0)
		into #soldi from fRulajeConturi(1, '371.%', null, @incLuna, null, null,'1901-1-1') f
		where exists(
		select 1 from gestiuni g where g.Cod_gestiune=rtrim(substring(f.cont, 5,20)) and (g.Tip_gestiune='V' or @soldc=1)
					)

	if (@soldc=0)
	insert into #soldi(data,gestiune,si, apare)
	select dateadd(d,1,@q_data_inchisa) as data, gestiune,sum(suma-sumae) as si, 0 as apare
	from
	(
	select gestiune,
		sum(case when tip_miscare='I' then round(convert(decimal(17,5), cantitate*(case when @q_tip_gestiune='A' then pret_cu_amanuntul else pret_de_stoc end)),2) else 0 end) as suma, 
		sum(case when tip_miscare='E' then round(convert(decimal(17,5), cantitate*(case when @q_tip_gestiune='A' then pret_amanunt_predator else pret_de_stoc end)),2) else 0 end) as sumaE
	from pozdoc p
	where subunitate=@q_sub and data between dateadd(d,1,@q_data_inchisa) and dateadd(d,-1,@incLuna) and 
		gestiune between @q_gestiune_jos and @q_gestiune_sus and (tip_miscare in ('I','E') or left(cont_de_stoc,4)='4428') and 
			exists (select cod_gestiune from gestiuni where subunitate=@q_sub and tip_gestiune=(case when @q_tip_gestiune='A' then 'A' else 'C' end)
						and cod_gestiune=gestiune)
				and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=p.Gestiune))
		/*and (:9=0 or :9=1 and TVA_neexigibil<>0 or :9=2 and TVA_neexigibil=0)*/
		group by gestiune
	union all
	select gestiune_primitoare, 
		sum(round(convert(decimal(17,5), cantitate*(case when @q_tip_gestiune='A' then pret_cu_amanuntul else pret_de_stoc end)),2)), 0
	from pozdoc p
	where subunitate=@q_sub and tip='TE' and data between dateadd(d,1,@q_data_inchisa) and dateadd(d,-1,@incLuna) and 
		gestiune_primitoare between @q_gestiune_jos and @q_gestiune_sus
		 and exists
			(select 1 from gestiuni where subunitate=@q_sub and tip_gestiune=(case when @q_tip_gestiune='A' then 'A' else 'C' end)
				and cod_gestiune=gestiune_primitoare) 
		and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=p.Gestiune_primitoare))
		/*and (:9=0 or :9=1 and TVA_neexigibil<>0 or :9=2 and TVA_neexigibil=0)*/
		group by Gestiune_primitoare
	union all
	select cod_gestiune,
		sum(round(convert(decimal(17,5), stoc*(case when @q_tip_gestiune='A' then Pret_cu_amanuntul else pret end)),2)), 0
	from istoricstocuri i
	where subunitate=@q_sub and data_lunii=@q_data_inchisa and 
		cod_gestiune between @q_gestiune_jos and @q_gestiune_sus
		and --cod_gestiune in 
		exists(select 1 from gestiuni where subunitate=@q_sub and tip_gestiune=(case when @q_tip_gestiune='A' then 'A' else 'C' end)
			and i.cod_gestiune=gestiuni.cod_gestiune) and stoc <> 0 
		and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=i.Cod_gestiune))
		group by Cod_gestiune
	) x
	group by gestiune

	if exists (select 1 from sysobjects where name='sold_init_gestiuni_willy' and xtype='U')
		update #soldi set si=isnull((select sum(sold) from sold_init_gestiuni_willy spec where spec.gestiune=#soldi.gestiune),0)

	select sum(r.suma-r.sumaE) as suma, r.Data, r.gestiune
	into #rapg_Fgrupat from 
	#rapg_grupat r group by r.data, r.gestiune

	--------- inserez linie de sold final pe zi si gestiune, in functie de soldul initial al perioadei si rulajul precedent
	insert into #soldi (data,Gestiune,si, apare)
	select r.data,r.gestiune,isnull(max(s.si),0)+sum(rr.suma) as si, 1 as apare
	from (select r.data,r.gestiune from #rapg_Fgrupat r group by r.data,r.gestiune) r 
		left join #soldi s on r.gestiune=s.Gestiune
		inner join #rapg_Fgrupat rr on r.gestiune=rr.gestiune and r.Data>=rr.Data 
	group by r.data, r.gestiune

	------------------------ select-ul final:
	--select @q_sub subunitate, rtrim(r.gestiune)+space(9-len(r.gestiune)) as gestiune, r.data, tip_document, numar_document, 
	--suma as suma_intrare, sumaE as suma_iesire,
	--isnull(si.si,0) sold_final_zi, @q_tip_gestiune tip_gestiune,
	--explicatii, --coresp, 
	--		(case when 0=1 then '01/01/2999' else r.data end) as data_ord, 
	--	rtrim(g.Denumire_gestiune) Denumire_gestiune, (case when Tip_document='AC' then sumaE-val_cu_amanuntul else 0 end) as discount
	--from #rapg_grupat r
	--left join gestiuni g on r.gestiune=g.Cod_gestiune
	--left join #soldi si on r.gestiune=si.Gestiune and r.Data=si.data and apare=1
	--where (abs(suma)+abs(sumae)>0 or si.si!=0) and r.data>=@q_datajos
	--order by r.gestiune, data_ord, numar_document

end try
begin catch
	set @eroare='raportGestiune:'+char(13)+ERROR_MESSAGE()
end catch

------------------------ stergere tabele temporare
if object_id('tempdb..#soldi') is not null drop table #soldi
if object_id('tempdb..#rapg_Fgrupat') is not null drop table #rapg_Fgrupat
if object_id('tempdb..#rapg_grupat') is not null drop table #rapg_grupat
if object_id('tempdb..#rapg') is not null drop table #rapg
	
if len(@eroare)>0 raiserror(16,1,@eroare)