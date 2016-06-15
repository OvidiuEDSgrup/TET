--***
create procedure rapFisaMijlocFix(@datajos datetime=null, @datasus datetime=null,
	@nrinv varchar(20)=null, @locm varchar(20)=null, @categorie varchar(20)=null, 
	@tipamortizare int=null,	--> filtru tip amortizare; [null, 0]=toate, 1=amortizat, 2=in curs de amortizare
	@lista int=null,			--> filtru tip: [null,1]=toate, 2=MF propriu-zise, 3= MF de natura ob inv
	@doarLuniModificari bit=0,	--> filtru luni: 1=doar luni care au modificari in afara amortizarilor
	@tipPatrimoniu smallint=3,	--> filtru pe tip patrimoniu: 3=Toate, 2=Privat, 1=Public
	@gestiune varchar(20)=null	--> filtru pe gestiune
	)
as
	set transaction isolation level read uncommitted
declare @eroare varchar(2000)
set @eroare=''
begin try
	if object_id('tempdb..#tmp') is not null drop table #tmp
	declare @subunitate varchar(10), @f_data bit, @f_nrinv bit, @f_locm bit, @f_categorie bit, @f_gestiune bit
	
	select	@subunitate=(select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),
			@f_data=(case when @datajos is null and @datasus is null then 0 else 1 end),
			@f_nrinv=(case when @nrinv is null then 0 else 1 end),
			@f_locm=(case when @locm is null then 0 else 1 end),
			@f_categorie=(case when @categorie is null then 0 else 1 end),
			@f_gestiune=(case when @gestiune is null then 0 else 1 end),
			
			@tippatrimoniu=(case when @tipPatrimoniu='2' then '' else @tipPatrimoniu end),
			@datajos=isnull(@datajos,'1901-1-1'),
			@datasus=isnull(@datasus,'2100-1-1'),
			@locm=@locm+'%',
			@tipamortizare=isnull(@tipamortizare,0),
			@lista=isnull(@lista,1)
	
	select f.Subunitate, f.Numar_de_inventar, f.Categoria, f.Data_lunii_operatiei, f.Felul_operatiei, f.Loc_de_munca, f.Gestiune,
			f.Comanda, f.Valoare_de_inventar, f.Valoare_amortizata, f.Valoare_amortizata_cont_8045, f.Valoare_amortizata_cont_6871,
			f.Amortizare_lunara, f.Amortizare_lunara_cont_8045, f.Amortizare_lunara_cont_6871, f.Durata, f.Obiect_de_inventar,
			f.Cont_mijloc_fix, f.Numar_de_luni_pana_la_am_int, f.Cantitate,
			--(case when isnull(m.detalii.value('(row/@descriere)[1]','varchar(1000)'),'')='' then m.denumire else m.detalii.value('(row/@descriere)[1]','varchar(1000)') end)
			m.denumire denumire, m.detalii.value('(row/@descriere)[1]','varchar(max)') descriere,
			m.data_punerii_in_functiune, m.cod_de_clasificare, f.Cont_amortizare,	--md.cod_de_clasificare cont_amortizare, s-a mutat contul de amortizare din mfix.dens.cod_de_clasificare in fisaMF.
			row_number() over (partition by f.Numar_de_inventar order by f.data_lunii_operatiei desc, f.felul_operatiei) as ordine_operatii, m.serie,
			mi.Tip_miscare, mi.numar_document, mi.data_miscarii, mi.tert, mi.factura, mi.pret, mi.tva, mi.cont_corespondent, 
			mi.Loc_de_munca_primitor, mi.Gestiune_primitoare, mi.Diferenta_de_valoare, mi.Data_sfarsit_conservare, mi.Subunitate_primitoare, mi.Procent_inchiriere,
			(case when mtpu.tert='' then '1' else isnull(mtp1.tert,md.Tip_amortizare) end) as tipPatrimoniu, isnull(mtp.tert,md.Tip_amortizare) as tipPatrimoniuAzi
	/*f.*, m.denumire,-- m.numar_de_inventar, 
	m.data_punerii_in_functiune, m.cod_de_clasificare*/
		into #tmp
		from mfix m
			inner join fisamf f on f.Subunitate=m.Subunitate and f.numar_de_inventar=m.numar_de_inventar
			left join mfix md on md.Numar_de_inventar=m.Numar_de_inventar and md.subunitate='DENS'
			left join mismf mi on f.numar_de_inventar=mi.numar_de_inventar and f.subunitate=mi.subunitate 
				and f.data_lunii_operatiei=mi.data_lunii_de_miscare and f.felul_operatiei not in ('A','1')
			LEFT outer join mismf mtp on f.subunitate=mtp.subunitate and f.Numar_de_inventar=mtp.Numar_de_inventar
				and mtp.tip_miscare='MTP' AND mtp.Data_miscarii=(
					select max(ma.Data_miscarii) from mismf ma where f.subunitate=ma.subunitate
						and f.Numar_de_inventar=ma.Numar_de_inventar and ma.tip_miscare='MTP'
						AND (ma.Data_lunii_de_miscare>=@datajos or ma.Data_lunii_de_miscare<=@datasus))
			LEFT outer join mismf mtp1 on f.subunitate=mtp1.subunitate and f.Numar_de_inventar=mtp1.Numar_de_inventar
				and mtp1.tip_miscare='MTP' and mtp1.Data_lunii_de_miscare<=f.Data_lunii_operatiei and not exists
					(select 1 from mismf mtp2 where mtp1.subunitate=mtp2.subunitate and mtp1.Numar_de_inventar=mtp2.Numar_de_inventar
				and mtp2.tip_miscare='MTP' and mtp2.Data_lunii_de_miscare<=f.Data_lunii_operatiei and mtp1.Data_lunii_de_miscare<mtp2.Data_lunii_de_miscare)
			OUTER APPLY (select top 1 tert from mismf mtpu where mtpu.Numar_de_inventar=m.Numar_de_inventar and mtpu.Data_lunii_de_miscare>f.Data_lunii_operatiei
				order by mtpu.Data_lunii_de_miscare) mtpu
		where 
		--and	
		f.subunitate=@subunitate
			and (@f_data=0 or f.Data_lunii_operatiei between @datajos and @datasus)
			and (@f_nrinv=0 or f.numar_de_inventar = @nrinv)
			and (@f_locm=0 or f.Loc_de_munca like @locm)
			and (@f_categorie=0 or f.Categoria like @categorie)
			and (@lista=1 or @lista=2 and f.obiect_de_inventar=0 or @lista=3 and f.obiect_de_inventar=1
			and (@tipamortizare=0 or @tipamortizare=1 and f.Valoare_de_inventar<=f.Valoare_amortizata 
						or @tipamortizare=2 and f.Valoare_de_inventar>f.Valoare_amortizata))
			and (@f_gestiune=0 or f.Gestiune=@gestiune)
			and (@tipPatrimoniu=3 or isnull(mtp.tert,md.Tip_amortizare)=@tipPatrimoniu)
			and f.Felul_operatiei<>'A'
	
	create index ind on #tmp(subunitate, numar_de_inventar, Data_lunii_operatiei, felul_operatiei)
	create unique index ind1 on #tmp(numar_de_inventar, ordine_operatii)
	
	select t.Subunitate, t.Numar_de_inventar, t.Categoria, t.Data_lunii_operatiei, t.Felul_operatiei,
			(case t.Felul_operatiei	when 1 then 'Date lunare'
									when 2 then 'Date implem.'
									when 3 then 'Intrare'
									when 4 then 'Modificare'
									when 5 then 'Iesire'
									when 6 then 'Transf intern'
									when 7 then 'Conservare'
									when 8 then 'Ies din cons'
									when 9 then 'Inchiriere' else '' end)
			nume_fel, t.Loc_de_munca, t.Gestiune,
			t.Comanda, t.Valoare_de_inventar, t.Valoare_amortizata, t.Valoare_amortizata_cont_8045, t.Valoare_amortizata_cont_6871,
			t.Amortizare_lunara, t.Amortizare_lunara_cont_8045, t.Amortizare_lunara_cont_6871, t.Durata, t.Obiect_de_inventar,
			t.Cont_mijloc_fix, t.Numar_de_luni_pana_la_am_int, t.Cantitate, t.denumire, t.descriere,
			t.data_punerii_in_functiune, t.cod_de_clasificare, 
			(case when tipPatrimoniu=1 then '8045' else t.cont_amortizare end) cont_amortizare,	--> pentru patrimoniu public s-a cerut sa se hardcodeze cont='8045'
			(case	when t.Tip_miscare is null or t.Felul_operatiei='2' then 'pe locm '+rtrim(t.Loc_de_munca)+', gest '+rtrim(t.Gestiune)
					when left(t.tip_Miscare,1)='I' then 'pe locm '+rtrim(ISNULL(t.Loc_de_munca,''))+', gest '+rtrim(ISNULL(t.Gestiune,''))+
						(case when  t.tip_miscare ='IAF' then ', tert '+rtrim(ISNULL(t.tert,''))+', factura '+rtrim(ISNULL(t.Factura,''))+' din '+ISNULL(convert(varchar(20),t.data_miscarii,103),'')
								--when t.tip_miscare ='isu' then ' isu'
							else '' end)
					when t.tip_miscare='ECS' then 'casare '
					--when t.tip_miscare ='Esu' then ' esu'
					--when t.tip_miscare ='MMF' then ' Mod. fact. furn. locm '+rtrim(t.Loc_de_munca)+' gestiune ' +rtrim(t.Gestiune)+' locm '+rtrim(t.Loc_de_munca_primitor)+' gestiune ' +rtrim(t.Gestiune_primitoare)
					when t.tip_miscare ='MRE' then 'diferenta din reevaluare '+convert(varchar(20),t.Diferenta_de_valoare)
					when t.tip_miscare ='MMF' then 'trecere la mijloc fix'
					when t.tip_miscare ='MFF' then 'modificare furnizor '+rtrim(t.Tert)+', factura '+rtrim(t.Factura)
					when t.tip_Miscare in ('TSE','TGU','TSU') then 'din'
							+(case when rtrim(t.Loc_de_munca)<>rtrim(t.Loc_de_munca_primitor) then ' locm '+rtrim(t.Loc_de_munca) else '' end)
							+(case when rtrim(t.Gestiune)<>rtrim(t.Gestiune_primitoare) then ' gestiunea '+rtrim(t.Gestiune) else '' end)
							+' in'
							+(case when rtrim(t.Loc_de_munca)<>rtrim(t.Loc_de_munca_primitor) then ' locm '+rtrim(t.Loc_de_munca_primitor) else '' end)
							+(case when rtrim(t.Gestiune)<>rtrim(t.Gestiune_primitoare) then ' gestiunea '+rtrim(t.Gestiune_primitoare) else '' end)
							--+(case when rtrim(t.Gestiune)<>rtrim(t.Gestiune_primitoare) then ' subunitatea '+rtrim(t.Subunitate) else '' end)
								--		+', gestiunea '+rtrim(t.Gestiune)+' din locm '+rtrim(t.Loc_de_munca_primitor)+', gest '+rtrim(t.Gestiune_primitoare)
				else '<'+t.Tip_miscare+'>'
			end) as explicatii, t.Numar_document numar, t.serie, (case when t.tipPatrimoniu='' then 2 else 1 end) tipPatrimoniu,
			(case when t.tipPatrimoniuAzi='' then 2 else 1 end) tipPatrimoniuAzi
		from #tmp t
		where (@doarLuniModificari=0 or exists (select 1 from #tmp f where t.subunitate=f.subunitate and
			t.Numar_de_inventar=f.Numar_de_inventar and  t.Data_lunii_operatiei=f.Data_lunii_operatiei and f.Felul_operatiei<>'1')
			)
	order by Numar_de_inventar, t.ordine_operatii
	
	--select * from #tmp
end try

begin catch
	set @eroare=ERROR_MESSAGE()+' (rapFisaMijlocFix '+convert(varchar(20),error_line())+')'
end catch

if object_id('tempdb..#tmp') is not null drop table #tmp
if len(@eroare)>0 raiserror(@eroare,16,1)
