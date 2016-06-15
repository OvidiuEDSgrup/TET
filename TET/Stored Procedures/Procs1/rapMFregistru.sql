--***
create procedure rapMFregistru (
	@tipimob varchar(1),	--> tip imobilizari: 1=M. fixe, 2=Obiecte de inventar, 3=MF dupa casare
	@lista varchar(1),		--> 1=Lista integrala, 2=MF propriu-zise, 3=MF de natura ob. de inv.
	@grupare int=2,			--> 2=l.m., 3=gestiuni, 4=categorii, 5=comenzi, 6=MF publice, 7=cont m.f.
	@data datetime, @cLocMunca varchar(20)=null, @pComanda varchar(100)=null, @serie varchar(20)=null,
	@cont varchar(20)=null, @categoria varchar(20)=null,
	@tippatrim varchar(1)=null, --> filtru pe tip patrimoniu: 3=toate, 2=privat, 1=public
	@nrInventar varchar(20)=null,
	@mfPublice smallint=0,		--> par. de filtrare m.f.: 0=toate, 1=doar m.f. cu m.f. publice asociate
	@tipActiv smallint=0,		--> tip active: 0=toate, 1=corporale, 2=necorporale
	@tipRaport varchar(2)='',	-->	''=reg. clasic, 'Li'=lista inv., '1g'=reg.cf.M.O.835/2008
	--> MFplus:
	@gestiune varchar(20)=null, @contAmortizare varchar(20)=null, @codClasificare varchar(20)=null, 
	@indbug varchar(20)=null, 	@grupGest varchar(20)=null, @exceptieLM smallint=0, 
	@ord_dupa_serie smallint=0, 
	@tipAmortizare smallint=0,		--> tip amortizare: 0=toate, 1=amortizate, 2=in curs de amortizare
	@tipConservare smallint=0,		--> tip conservare: 0=toate, 1=conservate, 2=neconservate
	@doarAmConta smallint=0 --> 0=toate, 1=doar cele cu amortizare contabila
	)
as
	/*	-- parametri pentru teste:
		declare @tipimob nvarchar(1),@lista nvarchar(1),@data datetime,@cLocMunca nvarchar(1),
		@pComanda nvarchar(4000), @serie varchar(20)
		select @tipimob=N'1',@lista=N'1',@data='2011-3-31 00:00:00',@cLocMunca=N'1',@pComanda=NULL
		-- apel procedura pentru teste:
		exec rapMFregistru @tipimob=@tipimob, @lista=@lista, @data=@data, @cLocMunca=@cLocMunca, 
		@pComanda=@pComanda, @serie=@serie
	--*/
	set transaction isolation level read uncommitted
	if object_id('tempdb..#mfix') is not null drop table #mfix
	if object_id('tempdb..#fisamf') is not null drop table #fisamf
	if object_id('tempdb..#rapRegistruMF') is not null drop table #rapRegistruMF
	
	declare @utilizator varchar(20), @sub char(9), @PrimTim int, @RADJ int, @fltGstUt int, @eLmUtiliz int
	select	@sub = isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'),'1'),
		@PrimTim = isnull((select Val_logica from par where tip_parametru='SP' and parametru='PRIMTIM'),0),
		@RADJ = isnull((select Val_logica from par where tip_parametru='SP' and parametru='RADJ'),0),
		@tippatrim=(case when @tippatrim='3' then null when @tippatrim='2' then '' else @tippatrim end), 
		@cont=@cont+'%',@categoria=@categoria+'%', @indbug=replace(isnull(@indbug,'%'),'.',''), 
		@grupGest=@grupGest+'%'
-->	pregatire "auto-filtrare" pe gestiune si loc de munca:
	declare @GestUtiliz table(valoare varchar(200), cod varchar(20))
	select @utilizator=dbo.fIaUtilizator('')
	insert into @GestUtiliz (valoare,cod)
	select valoare, cod_proprietate from fPropUtiliz(null) where cod_proprietate='GESTIUNE' and valoare<>''
	set	@fltGstUt=isnull((select count(1) from @GestUtiliz),0)
	declare @LmUtiliz table(valoare varchar(200))
	insert into @LmUtiliz(valoare)
	select cod from lmfiltrare f where f.utilizator=@utilizator
	declare @data31_12_2003 datetime
	select @data31_12_2003='12/31/2003'
	set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
		if @tipimob='g' return	--> smecheria aceasta e pt. prima rulare a functiei, deoarece altfel 
										--are sanse sa ia mult timp
	
	/**	rearanjare mijloace fixe astfel incat informatiile de tip catalog sa fie pe o singura linie
		pentru fiecare mijloc fix; 
		filtrele se aplica cat de repede, pentru a evita lucrul cu date care oricum nu vor fi folosite*/
		
	select m.Subunitate, m.Numar_de_inventar, m.Denumire, m.Serie, m.Tip_amortizare, 
		m.Cod_de_clasificare, m.Data_punerii_in_functiune, isnull(m1.serie,'') as tipImobilizare, 
		isnull(m1.Tip_amortizare,'') tipPatrimoniu, isnull(m4.serie,'') as MFpublic, mp.Denumire as numeMFPublic, 
		isnull(m1.Cod_de_clasificare,'') as contamortizare,
		isnull(m.detalii.value('(/row/@componenta)[1]', 'varchar(1)'), '') as componenta
	into #mfix
	from mfix m 
		left join mfix m1 on m1.Subunitate='DENS' and m.Numar_de_inventar=m1.Numar_de_inventar
		left join mfix m4 on m4.Subunitate='DENS4' and m.Numar_de_inventar=m4.Numar_de_inventar
		left join mfpublice mp on mp.Cod=m4.Serie
		where m.subunitate=@sub
			and (@nrInventar is null or m.Numar_de_inventar=@nrInventar)
			and (@serie is null or m.serie =@serie)
			and (@mfPublice=0 or mp.cod is not null)
			and (@codClasificare is null or m.Cod_de_clasificare like @codClasificare)
			--and (@contAmortizare is null or m1.Cod_de_clasificare like @contAmortizare)
			
	create clustered index indMF on #mfix(numar_de_inventar)
	
	declare @ReevaluareDeductibila int
	set @ReevaluareDeductibila=0
	if isnull((select val_alfanumerica from par where tip_parametru='MF' and parametru='CA681'),'6811') = isnull((select val_alfanumerica from par where tip_parametru='MF' and parametru='CA6871'),'6811')
		set @ReevaluareDeductibila=1
	if @RADJ=1 or 1=1 -- vom vedea cine plange
		set @ReevaluareDeductibila=0
	
	select a.subunitate,/* (case @grupare	when 2 then convert(varchar(20),a.Loc_de_munca)
					when 3 then convert(varchar(20),a.Gestiune)
					when 4 then convert(varchar(20),a.Categoria)
					when 5 then convert(varchar(20),a.Comanda ) else null end) as ordine,*/
	a.obiect_de_inventar, a.Numar_de_inventar, a.categoria as categoria, a.Loc_de_munca, 
	a.Gestiune, a.comanda, max(a.numar_de_luni_pana_la_am_int) as numar_luni,
	max(a.Valoare_de_inventar) as valoare_de_inventar, max(a.valoare_amortizata) as valoare_amortizata,
	max(a.amortizare_lunara) as amortizare_lunara, max(a.Durata) as durata,
	max(a.cantitate) as rezreev, max(isnull(fa.cantitate,0)) as dimrezreev, max(a.Cont_mijloc_fix) as Cont_mijloc_fix, a.Data_lunii_operatiei,
	max(b.Denumire) as denumire, max(b.Serie) as serie, max(b.Cod_de_clasificare) as cod_de_clasificare, 
	max(b.Data_punerii_in_functiune) as Data_punerii_in_functiune, 
	/*isnull(z.Data_miscarii,
		(case when b.Data_punerii_in_functiune<convert (datetime,@data31_12_2003) 
		then convert (datetime,@data31_12_2003) else b.Data_punerii_in_functiune end)) data_reevaluare,*/ 
	max(b.tipImobilizare) tipImobilizare, max(b.tipPatrimoniu) tipPatrimoniu, 
	max(b.MFpublic) MFpublic, max(b.numeMFPublic) numeMFPublic,
	max(rtrim(case @grupare	when 2 then convert(varchar(20),a.Loc_de_munca)
					when 3 then convert(varchar(20),a.Gestiune)
					when 5 then convert(varchar(20),a.Comanda)
					when 7 then convert(varchar(20),a.Cont_mijloc_fix)
					else 'Total' end)) as grupare,
	max(rtrim(case @grupare	when 6 then convert(varchar(20),b.MFpublic) 
		else convert(varchar(20),a.Categoria) end)) grupare2,
	max(isnull(a.Cont_amortizare,b.contamortizare)) contamortizare, sum(a.valoare_amortizata_cont_8045) valoare_amortizata_cont_8045,
	max(rtrim(substring(a.comanda,21,40))) as indicator,
	min(a.Numar_de_luni_pana_la_am_int) as luni_ramase,
	sum(case when @ReevaluareDeductibila=1 and fa.subunitate is not null then 0 else isnull(a.Valoare_amortizata_cont_6871,0) end) valoare_amortizata_cont_6871,
	sum(case when @ReevaluareDeductibila=1 and fa.subunitate is not null then 0 else isnull(a.Amortizare_lunara_cont_6871,0) end) Amortizare_lunara_cont_6871, 
	max(b.Tip_amortizare) as tip_amortizare,/*, max(k.diferenta_de_valoare) as difvalinvreev, 
	max(k.pret) as difamreev*/
	max(b.componenta) as componenta
	into #fisamf
	from fisamf a	
		inner join #mfix b on a.subunitate=b.subunitate and a.Numar_de_inventar=b.Numar_de_inventar
		left outer join fisamf fa on a.subunitate=fa.subunitate and a.Numar_de_inventar=fa.Numar_de_inventar and fa.felul_operatiei='A' and a.Data_lunii_operatiei=fa.Data_lunii_operatiei
		left outer join mismf d on a.subunitate=d.subunitate and a.Numar_de_inventar=d.Numar_de_inventar 
			and d.tip_miscare='CON' AND d.Data_sfarsit_conservare=(select 
			max(e.Data_sfarsit_conservare) from mismf e where a.subunitate=e.subunitate 
			and a.Numar_de_inventar=e.Numar_de_inventar and e.tip_miscare='CON' 
			AND e.Data_lunii_de_miscare<=a.Data_lunii_operatiei) 
		/*left outer join mismf z on @tipRaport not in ('1g') and a.subunitate= z.subunitate 
			and a.Numar_de_inventar= z.Numar_de_inventar and z.tip_miscare= 'MRE' 
			and z.Data_lunii_de_miscare< a.Data_lunii_operatiei 
		left outer join mismf k on @tipRaport not in ('1g') and a.subunitate= k.subunitate 
			and a.Numar_de_inventar= k.Numar_de_inventar and k.tip_miscare= 'MRE' 
			AND k.Data_lunii_de_miscare= a.Data_lunii_operatiei*/
	where a.subunitate=@sub and year(a.Data_lunii_operatiei)=year(@data) 
		and month(a.Data_lunii_operatiei)=month(@data) and a.felul_operatiei='1' 
		--<a fost repusa conditia a.felul_operatiei='1' pentru a nu se lua si poz. cu a.felul_operatiei<>'1'
		and (isnull(@cLocMunca, '')='' or @exceptieLM=0 and a.loc_de_munca like @cLocMunca+'%'
			or @exceptieLM=1 and a.loc_de_munca not like @cLocMunca+'%')
		--and ((@tipimob in ('1','3') and left(a.cont_mijloc_fix,1)!='8') or left(a.cont_mijloc_fix,1)='8')
		and (@pComanda is null or left(a.comanda,20)=@pComanda)
		and (@indbug='%' or substring(a.comanda,21,20) like @indbug)
		and (@eLmUtiliz=0 or exists(select 1 from @LmUtiliz pr where pr.valoare=a.loc_de_munca))
		and (@fltGstUt=0 or exists(select 1 from @GestUtiliz pr where pr.valoare=a.gestiune))
		and (@cont is null or a.Cont_mijloc_fix like @cont)
		and (@categoria is null or convert(varchar(2),a.Categoria) like @categoria)
		and (@contAmortizare is null or a.Cont_amortizare like @contAmortizare)
		and (@tipActiv=0 or @tipActiv=1 and a.Categoria<>'7' or @tipActiv=2 and a.Categoria='7')
		and (case when (@tipimob = 1 and @lista = 1 and b.tipImobilizare = '' ) then 1 --toate MF
			when (@tipimob = 1 and @lista = 2 and a.obiect_de_inventar=0 and b.tipImobilizare = '' ) then 1 --MF propriu-zise
			when (@tipimob = 1 and @lista = 3 and a.obiect_de_inventar=1 and b.tipImobilizare = '' ) then 1 --MF de nat. ob. inv.
			when (@tipimob = 2 and @lista = 1  and b.tipImobilizare =  'O') then 1 --ob. inv. - lista
			when (@tipimob = 3 and @lista = 1  and b.tipImobilizare = 'C') then 1 --MF dupa casare-lista
			else 0 end )=1
		and (@gestiune is null or a.Gestiune=@gestiune)
		and (@grupGest is null or a.Gestiune like @grupGest)
		and (@tipAmortizare=0 or (a.Valoare_de_inventar-a.Valoare_amortizata) 
			between (case when @tipAmortizare=1 then - (99999999999999) else 0.01 end) 
			and (case when @tipAmortizare=2 then 999999999999999 else 0 end))
		and (@tipConservare=0 or @tipConservare=1 and d.tip_miscare='CON' AND @data between 
			d.Data_lunii_de_miscare and d.Data_sfarsit_conservare or @tipConservare=2 
			and not (isnull(d.tip_miscare,'')='CON' AND @data between d.Data_lunii_de_miscare 
			and d.Data_sfarsit_conservare))
		/*and (@tipRaport in ('','1g','Li') or @tipRaport='1a' and b.tip_amortizare<>'1' or @tipRaport in 
			('1b','1c') and b.tip_amortizare='1') and (@tipRaport in ('','1g','Li') 
			or k.Data_lunii_de_miscare= a.Data_lunii_operatiei) */
		and (@tipRaport<>'Li' or (a.Valoare_de_inventar)>0 /*fara iesiri in lista de inv.*/)
		and (@doarAmConta=0 or a.Amortizare_lunara_cont_6871<>0)
	group by a.obiect_de_inventar, a.numar_de_inventar,a.categoria,a.loc_de_munca,a.gestiune,a.comanda, 
		a.subunitate, a.Data_lunii_operatiei/*,	isnull(z.Data_miscarii,
			(case when b.Data_punerii_in_functiune<convert (datetime,@data31_12_2003) 
			then convert (datetime,@data31_12_2003) else b.Data_punerii_in_functiune end))*/

select 
	a.Numar_de_inventar, left(convert(char(2),a.Categoria),1) as categ, 
	ltrim(convert(char(2),a.Categoria)) as subcateg, a.Loc_de_munca, a.Gestiune, 
	max(a.Valoare_de_inventar) as valoare_de_inventar, 
	/*max(a.valoare_amortizata) as valoare_amortizata, 
	max(a.valoare_amortizata_cont_8045) valoare_amortizata_cont_8045,
	max(a.amortizare_lunara) as amortizare_lunara, */
	max((case when @PrimTim=1 and @grupare=2 and a.Loc_de_munca='PTR' then 0 
		else a.Valoare_amortizata end)) as valoare_amortizata, 
	max((case when @PrimTim=1 and @grupare=2 and a.Loc_de_munca='PTR' then 0 
		when @doarAmConta=1 then a.Valoare_amortizata_cont_6871 
		else a.Valoare_amortizata_cont_8045 end)) as valoare_amortizata_cont_8045, 
	max((case when @PrimTim=1 and @grupare=2 and a.Loc_de_munca='PTR' then 0 
		when @doarAmConta=1 then a.Amortizare_lunara_cont_6871 
		else a.Amortizare_lunara end)) as amortizare_lunara, 
	max(a.Durata) as durata, min(luni_ramase) luni_ramase, --1 as cantitate, 
	max(a.Denumire) as denumire, max(a.Serie) as serie, 
	max(a.tip_amortizare) as tip_amortizare, max(a.Cod_de_clasificare) as cod_de_clasificare, 
	max(a.Data_punerii_in_functiune) as Data_punerii_in_functiune, 
	max(lm.denumire) as den_lm, max(left(g.denumire_gestiune,30)) as denumire_gestiune, 
	--@grupare: 2=locm, 3=gestiuni, 4=categorii, 5=comenzi, 6=MFpublice, 7=cont m.f.
	max(h.Valoare_de_inventar) as valinvlunaant, 
	/*max(h.Amortizare_lunara) as amlunaant, */max(i.col2) as cotaamlin, max(i.col3) as cotaamdegr, 
	max(i.col6) as duramdegr, /*max(i.col7) as duramlin, max(j.indice_total) as indinflatie, 
	max(a.difvalinvreev) as difvalinvreev, max(a.difamreev) as difamreev, 
	max(a.data_reevaluare) as data_reevaluare, */max(a.Cont_mijloc_fix) as Cont_mijloc_fix, 
	max(a.rezreev) as rezreev, max(a.dimrezreev) as dimrezreev, 
	max(a.valoare_amortizata_cont_6871) valoare_amortizata_cont_6871, max(a.Amortizare_lunara_cont_6871) amortizare_lunara_cont_6871, 
	--datele de mai jos sunt doar pt. RDL
	max(case isnull(m.tert,a.tipPatrimoniu) when null then 3 when '' then 2 
		else isnull(m.tert,a.tipPatrimoniu) end) as tipPatrimoniu,
	max(contamortizare) contamortizare, max(a.indicator) as indicator, 
	a.comanda, max(com.descriere) as descriere, max(numar_luni) numar_luni,
	a.categoria as categoria,
	max(a.componenta) as componenta, 
	max(a.grupare) as grupare, 
	max(a.grupare)+
		max(case @grupare when 1 then 'Unitate'
						when 2 then ' - '+rtrim(lm.Denumire)
						when 3 then ' - '+rtrim(left(g.Denumire_gestiune,30))
						when 5 then ' - '+rtrim(com.descriere)
						when 7 then ' - '+rtrim(c.Denumire_cont)
						else '' end) as numeGrupare,
	max(a.grupare2) grupare2,
	max(rtrim(case @grupare when 6 then rtrim(a.MFpublic)+' ('+
		convert(varchar(200),rtrim(a.numeMFPublic))+')' 
		else convert(varchar(200),a.categoria) end)) numeGrupare2
INTO #rapRegistruMF
FROM #fisamf a
	/*left outer join mismf d on a.subunitate=d.subunitate and a.Numar_de_inventar=d.Numar_de_inventar
		and d.tip_miscare='CON' and d.Data_sfarsit_conservare=(select max(e.Data_sfarsit_conservare)
			from mismf e where a.subunitate= e.subunitate and a.Numar_de_inventar= e.Numar_de_inventar
				and e.tip_miscare='CON')*/ --Mircea, 22.08.2012: l-am mutat mai sus
	left outer join lm on a.Loc_de_munca=lm.cod
	left outer join gestiuni g on a.subunitate= g.subunitate and a.Gestiune=g.cod_gestiune
	left outer join fisamf h on a.subunitate= h.subunitate and a.Numar_de_inventar= h.Numar_de_inventar
		and h.Data_lunii_operatiei=dbo.bom(@data)-1 and h.felul_operatiei='1'
		--< tabele in plus, pt. integrare in Magic:
	left outer join coefmf i on i.DUR=h.durata
	/*left outer join mf_ipc j on j.data=a.Data_lunii_operatiei and j.an=year(a.data_reevaluare)
		and j.luna=month(a.data_reevaluare)*/
		-->
	left outer join comenzi com on com.comanda=a.comanda and a.subunitate=com.subunitate
	left outer join mismf m on a.subunitate=m.subunitate and a.Numar_de_inventar=m.Numar_de_inventar
		and m.tip_miscare='MTP' AND m.Data_miscarii=(select max(ma.Data_miscarii) from mismf ma where 
				a.subunitate=ma.subunitate and a.Numar_de_inventar=ma.Numar_de_inventar 
				and ma.tip_miscare='MTP' AND ma.Data_lunii_de_miscare<=@data)
	left join conturi c on c.Cont=a.Cont_mijloc_fix
WHERE (@tippatrim is null or isnull(m.tert,a.tipPatrimoniu)=@tippatrim)
group by a.numar_de_inventar,a.categoria,a.loc_de_munca,a.gestiune,a.comanda
/*order by --ltrim(convert(char(2),a.Categoria)), max(a.Serie), a.Numar_de_inventar --asa a fost pana-n 25.08.2012
	max(a.grupare), subcateg, (case when @ord_dupa_serie=1 then max(a.serie) else ' ' end), 
	a.Numar_de_inventar
*/

if exists (select 1 from sysobjects o where o.name='rapMFregistruSP')
begin
	declare @sesiune varchar(50), @parXML XML
	set @parXML=(select convert(varchar(10),@data,101) as data, @tipRaport as tipRaport for xml raw)
	exec rapMFregistruSP @sesiune, @parXML -- pt. prelucare #rapRegistruMF
end

select 
	Numar_de_inventar, categ, 
	subcateg, Loc_de_munca, Gestiune, 
	valoare_de_inventar, 
	valoare_amortizata, 
	valoare_amortizata_cont_8045, 
	amortizare_lunara, 
	durata, luni_ramase, --1 as cantitate, 
	denumire, serie, 
	tip_amortizare, cod_de_clasificare, 
	Data_punerii_in_functiune, 
	den_lm, denumire_gestiune, 
	grupare, valinvlunaant, 
	cotaamlin, cotaamdegr, 
	duramdegr, Cont_mijloc_fix, 
	rezreev, dimrezreev, 
	valoare_amortizata_cont_6871, amortizare_lunara_cont_6871, 
	tipPatrimoniu,
	contamortizare, indicator, 
	comanda, descriere, numar_luni,
	categoria, componenta,
	numeGrupare,
	grupare2,
	numeGrupare2
FROM #rapRegistruMF
order by grupare, subcateg, (case when @ord_dupa_serie=1 then serie else ' ' end), Numar_de_inventar

if object_id('tempdb..#mfix') is not null drop table #mfix
if object_id('tempdb..#fisamf') is not null drop table #fisamf
if object_id('tempdb..#rapRegistruMF') is not null drop table #rapRegistruMF
