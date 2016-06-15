--***
create procedure rapMFanexereev (@sesiune varchar(50)=null, @tipAnexa varchar(2)='1a',	-->	'1a/1b/.../1f'=anexe reev.
	@data datetime, @lm varchar(20)=null, @com varchar(20)=null, 
	@contMF varchar(20)=null, @categ varchar(20)=null, @nrInv varchar(20)=null, 
	@gest varchar(20)=null, @contAm/*cont amortizare*/ varchar(20)=null, @codClasif varchar(20)=null, 
	@indBug varchar(20)=null, @grupGest varchar(20)=null, @exceptieLM smallint=0,
	@ordonare varchar(20)='c'	--> 'c'=numar de inventar, 'n'=denumire, 'v'=valoare de inventar (reevaluata)
	--@serie varchar(20)=null, 
	--@tipImob varchar(1),	--> tip imobilizari: 1=M. fixe, 2=Obiecte de inventar, 3=MF dupa casare
	--@subtipImob varchar(1)		--> 1=toate, 2=MF propriu-zise, 3=MF de natura ob. de inv.
	--@grupare int=2,			--> 2=l.m., 3=gestiuni, 4=categorii, 5=comenzi, 6=MF publice, 7=cont m.f.
	--@mfPublice smallint=0,		--> par. de filtrare m.f.: 0=toate, 1=doar m.f. cu m.f. publice asociate
	--@ord_dupa_serie smallint=0, 
	--@tipAmortizare smallint=0,		--> tip amortizare: 0=toate, 1=amortizate, 2=in curs de amortizare
	--@tipConservare smallint=0		--> tip conservare: 0=toate, 1=conservate, 2=neconservate
	--@doaramconta smallint=0 --> 0=toate, 1=doar cele cu amortizare contabila
	)
as
set transaction isolation level read uncommitted

declare @eroare varchar(max)
select @eroare=''
begin try
	if object_id('tempdb..#mfixanexereev') is not null drop table #mfixanexereev
	if object_id('tempdb..#fisamfanexereev') is not null drop table #fisamfanexereev

	declare @utilizator varchar(20), @sub char(9), @fltGstUt int, @eLmUtiliz int, --@PrimTim int, 
		@tipActive smallint,		--> tip active: 0=toate, 1=corporale, 2=necorporale
		@tipPatrim varchar(1) --> filtru pe tip patrimoniu: 3=toate, 2=privat, 1=public

	select @utilizator=dbo.fIaUtilizator('')
	select	@sub = isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'),'1'),
		--@PrimTim = isnull((select Val_logica from par where tip_parametru='SP' and parametru='PRIMTIM'),0),
		@tippatrim=(case when @tipAnexa='1b' then '1' else '' /*'2'*/ end), 
		@contMF=@contMF+'%',@categ=@categ+'%', @indbug=replace(isnull(@indbug,'%'),'.',''), 
		@grupGest=@grupGest+'%', @tipActive=1
	--> pregatire "auto-filtrare" pe gestiune si loc de munca:
	declare @GestUtiliz table(valoare varchar(200), cod varchar(20))
	insert into @GestUtiliz (valoare,cod)
	select valoare, cod_proprietate from fPropUtiliz(null) where cod_proprietate='GESTIUNE' and valoare<>''
	set	@fltGstUt=isnull((select count(1) from @GestUtiliz),0)
	declare @LmUtiliz table(valoare varchar(200))
	insert into @LmUtiliz(valoare)
	select cod from lmfiltrare l where l.utilizator=@utilizator
	declare @data31_12_2003 datetime
	select @data31_12_2003='12/31/2003'
	set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
	
	if @data='1900-1-1' return	--> smecheria aceasta e pt. prima rulare a functiei, deoarece altfel 
										--are sanse sa ia mult timp
	
	/**	rearanjare mijloace fixe astfel incat informatiile de tip catalog sa fie pe o singura linie
		pentru fiecare mijloc fix; 
		filtrele se aplica cat de repede, pentru a evita lucrul cu date care oricum nu vor fi folosite*/
		
	select m.Subunitate, m.Numar_de_inventar, m.Denumire, m.Serie, m.Tip_amortizare, 
		m.Cod_de_clasificare, m.Data_punerii_in_functiune, m1.serie as tipImobilizare, 
		m1.Tip_amortizare tipPatrimoniu, --isnull(m4.serie,'') as MFpublic, mfp.Denumire as numeMFPublic, 
		m1.Cod_de_clasificare as contamortizare	--s-a mutat contul de amortizare din mfix.cod_de_clasificare (subunitate=DENS) in fisaMF.
	into #mfixanexereev
	from mfix m 
		left join mfix m1 on m1.Subunitate='DENS' and m.Numar_de_inventar=m1.Numar_de_inventar
		left join mfix m4 on m4.Subunitate='DENS4' and m.Numar_de_inventar=m4.Numar_de_inventar
		--left join mfpublice mfp on mfp.Cod=m4.Serie
		where m.subunitate=@sub
			and (@nrInv is null or m.Numar_de_inventar=@nrInv)
			--and (@serie is null or m.serie =@serie)
			--and (@mfPublice=0 or mfp.cod is not null)
			and (@codClasif is null or m.Cod_de_clasificare like @codClasif)
			--and (@contAm is null or m1.Cod_de_clasificare like @contAm)
			
	create clustered index indMF on #mfixanexereev(numar_de_inventar)
	
	select a.subunitate, /*(case @grupare	when 2 then convert(varchar(20),a.Loc_de_munca)
					when 3 then convert(varchar(20),a.Gestiune)
					when 4 then convert(varchar(20),a.Categoria)
					when 5 then convert(varchar(20),a.Comanda ) else null end) as ordine,*/
	a.Numar_de_inventar, a.categoria as categoria, a.obiect_de_inventar, a.Loc_de_munca, 
	a.Gestiune, a.comanda, --/*max*/(a.numar_de_luni_pana_la_am_int) as numar_luni,
	/*max*/(a.Valoare_de_inventar) as valoare_de_inventar, /*max*/(a.valoare_amortizata) as valoare_amortizata,
	/*max*/(a.amortizare_lunara) as amortizare_lunara, /*max*/(a.Durata) as durata,
	/*max*/(a.cantitate) as rezreev, /*max*/(a.Cont_mijloc_fix) as Cont_mijloc_fix, Data_lunii_operatiei,
	/*max*/(b.Denumire) as denumire, /*max*/(b.Serie) as serie, /*max*/(b.Cod_de_clasificare) as cod_de_clasificare, 
	/*max*/(b.Data_punerii_in_functiune) as Data_punerii_in_functiune, 
	isnull((select top 1 z.data_miscarii from mismf z where a.subunitate= z.subunitate 
		and a.Numar_de_inventar= z.Numar_de_inventar and z.tip_miscare= 'MRE' 
		and z.Data_lunii_de_miscare< a.Data_lunii_operatiei order by z.Data_lunii_de_miscare desc),
		(case when b.Data_punerii_in_functiune<convert (datetime,@data31_12_2003) 
		then convert (datetime,@data31_12_2003) else b.Data_punerii_in_functiune end)) data_reevaluare, 
	/*max*/(b.tipPatrimoniu) tipPatrimoniu, /*/*max*/(b.tipImobilizare) tipImobilizare, 
	/*max*/(b.MFpublic) MFpublic, /*max*/(b.numeMFPublic) numeMFPublic,
	/*max*/(rtrim(case @grupare	when 2 then convert(varchar(20),a.Loc_de_munca)
					when 3 then convert(varchar(20),a.Gestiune)
					when 5 then convert(varchar(20),a.Comanda)
					when 7 then convert(varchar(20),a.Cont_mijloc_fix)
					else 'Total' end)) as grupare,
	/*max*/(rtrim(case @grupare	when 6 then convert(varchar(20),b.MFpublic) 
		else convert(varchar(20),a.Categoria) end)) grupare2,*/
	/*max*/(a.Cont_amortizare) contamortizare, /*sum*/(valoare_amortizata_cont_8045) valoare_amortizata_cont_8045,
	/*max*/(rtrim(substring(a.comanda,21,40))) as indicator,
	/*max*/(a.Numar_de_luni_pana_la_am_int) as luni_ramase,
	/*sum*/(isnull(a.Valoare_amortizata_cont_6871,0)) valoare_amortizata_cont_6871,
	/*sum*/(isnull(a.Amortizare_lunara_cont_6871,0)) Amortizare_lunara_cont_6871, 
	/*max*/(b.Tip_amortizare) as tip_amortizare, /*max*/(k.diferenta_de_valoare) as difvalinvreev, 
	/*max*/(k.pret) as difamreev,
		(case @ordonare when 'c' then a.numar_de_inventar
						when 'n' then b.denumire
						else '' end) as ordonare
		into #fisamfanexereev
	from fisamf a	
		inner join #mfixanexereev b on a.subunitate=b.subunitate and a.Numar_de_inventar=b.Numar_de_inventar
		/*left outer join mismf z on @tipAnexa not in ('1g') and a.subunitate= z.subunitate 
			and a.Numar_de_inventar= z.Numar_de_inventar and z.tip_miscare= 'MRE' 
			and z.Data_lunii_de_miscare< a.Data_lunii_operatiei */
		left outer join mismf k on @tipAnexa not in ('1g') and a.subunitate= k.subunitate 
			and a.Numar_de_inventar= k.Numar_de_inventar and k.tip_miscare= 'MRE' 
			AND k.Data_lunii_de_miscare= a.Data_lunii_operatiei
	where a.subunitate=@sub and year(a.Data_lunii_operatiei)=year(@data) 
		and month(a.Data_lunii_operatiei)=month(@data) and a.felul_operatiei='1' 
		--a fost repusa cond. "a.felul_operatiei='1'" pentru a nu se lua si poz.cu a.felul_operatiei<>'1'
		and (isnull(@lm, '')='' or @exceptieLM=0 and a.loc_de_munca like @lm+'%'
			or @exceptieLM=1 and a.loc_de_munca not like @lm+'%')
		--and (@tipimob in ('1','3') and left(a.cont_mijloc_fix,1)!='8' or left(a.cont_mijloc_fix,1)='8')
		and (@com is null or left(a.comanda,20)=@com)
		and (@indbug='%' or substring(a.comanda,21,20) like @indbug)
		and (@eLmUtiliz=0 or exists(select 1 from @LmUtiliz pr where pr.valoare=a.loc_de_munca))
		and (@fltGstUt=0 or exists(select 1 from @GestUtiliz pr where pr.valoare=a.gestiune))
		and (@contMF is null or a.Cont_mijloc_fix like @contMF)
		and (@categ is null or convert(varchar(2),a.Categoria) like @categ)
		and (@contAm is null or a.Cont_amortizare like @contAm)
		and (@tipActive=0 or @tipActive=1 and a.Categoria<>'7' or @tipActive=2 and a.Categoria='7')
		/*and (case when (@tipimob = 1 and @subtipimob = 1) then 1 --toate MF
			when (@tipimob = 1 and @subtipimob = 2 and a.obiect_de_inventar=0) then 1 --MF propriu-zise
			when (@tipimob = 1 and @subtipimob = 3 and a.obiect_de_inventar=1) then 1 --MF de nat. ob. inv.
			when (@tipimob = 2 and @subtipimob = 1  and b.tipImobilizare =  'O') then 1 --ob. inv. - lista
			when (@tipimob = 3 and @subtipimob = 1  and b.tipImobilizare = 'C') then 1 --MF dupa casare-lista
			else 0 end )=1*/
		and (@gest is null or a.Gestiune=@gest)
		and (@grupGest is null or a.Gestiune like @grupGest)
		/*and (@tipAmortizare=0 or (a.Valoare_de_inventar-a.Valoare_amortizata) 
			between (case when @tipAmortizare=1 then - (99999999999999) else 0.01 end) 
			and (case when @tipAmortizare=2 then 999999999999999 else 0 end))
		and (@tipConservare=0 or @tipConservare=1 and d.tip_miscare='CON' AND @data between 
			d.Data_lunii_de_miscare and d.Data_sfarsit_conservare or @tipConservare=2 
			and not (isnull(d.tip_miscare,'')='CON' AND @data between d.Data_lunii_de_miscare 
			and d.Data_sfarsit_conservare))*/
		and (@tipAnexa in ('','1g','Li') or @tipAnexa='1a' and b.tip_amortizare<>'1' 
		/*	Am inteles de la dl. Vintila ca anexa 1b trebuie sa contina toate MF publice (la bugetari MF-urile publice se amortizeaza extrabilantier (8045), adica "nu se amortizeaza".*/
			or @tipAnexa='1b' and b.tip_amortizare like '%'
			or @tipAnexa='1c' and b.tip_amortizare='1') 
			and (@tipAnexa in ('','1g','Li') 
			or k.Data_lunii_de_miscare= a.Data_lunii_operatiei) 
	/*group by a.obiect_de_inventar, a.numar_de_inventar,a.categoria,a.loc_de_munca,a.gestiune,a.comanda, 
		a.subunitate, Data_lunii_operatiei,	isnull(z.Data_miscarii,
			(case when b.Data_punerii_in_functiune<convert (datetime,@data31_12_2003) 
			then convert (datetime,@data31_12_2003) else b.Data_punerii_in_functiune end))*/

select 
	a.Numar_de_inventar, left(convert(char(2),a.Categoria),1) as categ, 
	ltrim(convert(char(2),a.Categoria)) as subcateg, a.Loc_de_munca, a.Gestiune, 
	/*max*/(a.Valoare_de_inventar) as valoare_de_inventar, 
	/*max*/(a.valoare_amortizata) as valoare_amortizata, 
	/*max*/(a.valoare_amortizata_cont_8045) valoare_amortizata_cont_8045,
	/*max*/(a.amortizare_lunara) as amortizare_lunara, 
	/*/*max*/((case when @PrimTim=1 and @grupare=2 and a.Loc_de_munca='PTR' then 0 
		else a.Valoare_amortizata end)) as valoare_amortizata, 
	/*max*/((case when @PrimTim=1 and @grupare=2 and a.Loc_de_munca='PTR' then 0 
		when @doaramconta=1 then a.Valoare_amortizata_cont_6871 
		else a.Valoare_amortizata_cont_8045 end)) as valoare_amortizata_cont_8045, 
	/*max*/((case when @PrimTim=1 and @grupare=2 and a.Loc_de_munca='PTR' then 0 
		when @doaramconta=1 then a.Amortizare_lunara_cont_6871 
		else a.Amortizare_lunara end)) as amortizare_lunara, */
	/*max*/(a.Durata) as durata, /*max*/(luni_ramase) luni_ramase, --1 as cantitate, 
	/*max*/(a.Denumire) as denumire, /*max*/(a.Serie) as serie, 
	/*max*/(a.tip_amortizare) as tip_amortizare, /*max*/(a.Cod_de_clasificare) as cod_de_clasificare, 
	/*max*/(a.Data_punerii_in_functiune) as Data_punerii_in_functiune, 
	/*max*/(lm.denumire) as den_lm, /*max*/(left(g.denumire_gestiune,30)) as denumire_gestiune, 
	--/*max*/(a.grupare) grupare,  --2=locm, 3=gestiuni, 4=categorii, 5=comenzi, 6=MFpublice, 7=cont m.f.
	/*max*/(h.Valoare_de_inventar) as valinvlunaant, 
	/*max*/(h.Amortizare_lunara) as amlunaant, /*max*/(i.col2) as cotaamlin, /*max*/(i.col3) as cotaamdegr, 
	/*max*/(i.col6) as duramdegr, /*max*/(j.indice_total) as indinflatie, 
	/*max*/(a.difvalinvreev) as difvalinvreev, /*max*/(a.difamreev) as difamreev, 
	/*max*/(a.data_reevaluare) as data_reevaluare, /*max*/(a.Cont_mijloc_fix) as Cont_mijloc_fix, 
	/*max*/(a.rezreev) as rezreev,
	a.valoare_de_inventar-a.valoare_amortizata as nouavaldeamortizat,
	a.difvalinvreev-a.difamreev as difreevdurram,
	a.valoare_de_inventar-a.valoare_amortizata-(a.difvalinvreev-a.difamreev) as ramasdeamortizat,
	h.Valoare_de_inventar-(a.valoare_de_inventar-a.valoare_amortizata-(a.difvalinvreev-a.difamreev)) as valamortizata
	,a.durata*12 duratatot
	,a.durata*12-luni_ramase duratacon
	,100*(a.durata*12-luni_ramase)/(a.durata*12) as grut
	,j.indice_total/100 as IPC
	/*/*max*/(case isnull(m.tert,a.tipPatrimoniu) when null then 3 when '' then 2 
		else isnull(m.tert,a.tipPatrimoniu) end) as tipPatrimoniu,
	/*max*/(contamortizare) contamortizare, /*max*/(a.indicator) as indicator, 
	a.comanda, /*max*/(cc.descriere) as descriere, /*max*/(numar_luni) numar_luni,
	/*max*/(a.Amortizare_lunara_cont_6871) amortizare_lunara_cont_6871, 
	/*max*/(a.valoare_amortizata_cont_6871) valoare_amortizata_cont_6871,
	/*max*/(a.grupare)+
		/*max*/(case @grupare when 1 then 'Unitate'
						when 2 then ' - '+rtrim(lm.Denumire)
						when 3 then ' - '+rtrim(left(g.Denumire_gestiune,30))
						when 5 then ' - '+rtrim(cc.descriere)
						when 7 then ' - '+rtrim(c.Denumire_cont)
						else '' end) as numeGrupare,
	/*max*/(a.grupare2) grupare2,
	/*max*/(rtrim(case @grupare when 6 then rtrim(a.MFpublic)+' ('+
		convert(varchar(200),rtrim(a.numeMFPublic))+')' 
		else convert(varchar(200),a.categoria) end)) numeGrupare2*/
FROM #fisamfanexereev a
	left outer join lm on a.Loc_de_munca=lm.cod
	left outer join gestiuni g on a.subunitate= g.subunitate and a.Gestiune=g.cod_gestiune
	left outer join fisamf h on a.subunitate= h.subunitate and a.Numar_de_inventar= h.Numar_de_inventar
		and h.Data_lunii_operatiei=dbo.bom(@data)-1 and h.felul_operatiei='1'
	left outer join coefmf i on i.DUR=h.durata
	left outer join mf_ipc j on j.data=a.Data_lunii_operatiei and j.an=year(a.data_reevaluare)
		and j.luna=month(a.data_reevaluare)
	left outer join comenzi cc on cc.comanda=a.comanda and a.subunitate=cc.subunitate
	left outer join mismf m on a.subunitate=m.subunitate and a.Numar_de_inventar=m.Numar_de_inventar
		and m.tip_miscare='MTP' AND m.Data_miscarii=(select max(ma.Data_miscarii) from mismf ma where 
				a.subunitate=ma.subunitate and a.Numar_de_inventar=ma.Numar_de_inventar 
				and ma.tip_miscare='MTP' AND ma.Data_lunii_de_miscare<=@data)
	left join conturi c on c.Cont=a.Cont_mijloc_fix
WHERE (@tippatrim is null or isnull(m.tert,a.tipPatrimoniu)=@tippatrim)
--group by a.numar_de_inventar,a.categoria,a.loc_de_munca,a.gestiune,a.comanda
order by --/*max*/(a.grupare), 
	subcateg, --(case when @ord_dupa_serie=1 then /*max*/(a.serie) else ' ' end), 
	a.ordonare,
	a.valoare_de_inventar desc
end try
begin catch
	set @eroare=error_message()+'('+OBJECT_NAME(@@PROCID)+')'
end catch
	if object_id('tempdb..#mfixanexereev') is not null drop table #mfixanexereev
	if object_id('tempdb..#fisamfanexereev') is not null drop table #fisamfanexereev
	--> raportarea erorilor catre raport astfel incat sa nu deranjeze prea mult apelul din ASiSplus:
	if len(@eroare)>0
	begin
		--> pt UniPaas trebuie sa apara toate coloanele declarate in raportul respectiv, altfel apare o eroare fatala - cu iesire din aplicatie:
		select
		'<EROARE>' Numar_de_inventar, '' categ, '' subcateg, '' Loc_de_munca, '' Gestiune, 0 valoare_de_inventar, 0 valoare_amortizata, 0 valoare_amortizata_cont_8045, 0 amortizare_lunara, 0 durata, 0 luni_ramase
		,@eroare denumire, '' serie, '' tip_amortizare, '' cod_de_clasificare, '1901-1-1' Data_punerii_in_functiune, '' den_lm, '' denumire_gestiune, 0 valinvlunaant, 0 amlunaant, 0 cotaamlin
		,0 cotaamdegr, 0 duramdegr, 0 indinflatie, 0 difvalinvreev, 0 difamreev, '1901-1-1' data_reevaluare, '' Cont_mijloc_fix, 0 rezreev, 0 nouavaldeamortizat, 0 difreevdurram, 0 ramasdeamortizat
		,0 valamortizata, 0 duratatot, 0 duratacon, 0 grut, 0 IPC
		raiserror(@eroare,16,1)
	end
