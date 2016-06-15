--***
create procedure rapFisaContului(
	@subtotaluri int=0	-->	0= fara, 1=pe jurnale, 2=pe locuri de munca, 3=pe indicatori
	,@DataJos datetime,@DataSus datetime,
	@CCont varchar(40)='',@CuSoldRulaj bit=0, @EOMDataSus datetime=null, @locm varchar(20)=null,
	@valuta varchar(20) = null, @inValuta bit = 0, @intabela bit=0
	,@indicator varchar(100)=null
	,@centralizare int=0)
as
/*
exec rapFisaContului	@subtotaluri =0, @DataJos='2013-01-01',@DataSus='2013-12-31',@CCont='444.01',@CuSoldRulaj=0, @EOMDataSus=null, @locm=null,
	@valuta = null, @inValuta = 0, @intabela =0	,@indicator =null	,@centralizare =0
*/
declare @eroare varchar(max), @xml xml
select @eroare=''
begin try
set @EOMDataSus=isnull(@EOMDataSus,dbo.eom(@DataSus))
set transaction isolation level read uncommitted
declare @subunitate char(9), @q_locm varchar(200), @eLmUtiliz int
select @subunitate=max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'
select @indicator=@indicator+(case when isnull(@indicator,'')='' then '' else '%' end)

if object_id('tempdb..#componenteConturi') is not null drop table #componenteConturi
if object_id('tempdb..#solduri') is not null drop table #solduri
if object_id('tempdb..#conturi') is not null drop table #conturi
if object_id('tempdb..#prelExplicatii') is not null drop table #prelExplicatii
if object_id('tempdb..#final') is not null drop table #final
if object_id('tempdb..#raport') is not null drop table #raport

set @xml = (select	@subtotaluri subtotaluri, convert(char(10), @DataJos, 101) DataJos, convert(char(10), @DataSus, 101) DataSus, 
						@CCont CCont, @CuSoldRulaj CuSoldRulaj, convert(char(10), @EOMDataSus, 101) EOMDataSus, @locm locm, 
						@valuta valuta, @inValuta inValuta, @intabela intabela, 
						@indicator indicator, @centralizare centralizare for xml raw)

if object_id('tempdb..#fisa') is null
begin
	create table #fisa(cont varchar(100))
	exec rapFisaContului_tabela
end

if (@valuta is null) set @valuta=''
if exists (select 1 from par where Tip_parametru='GE' and Parametru='rulajelm' and Val_logica=1)
	set @locm=ISNULL(@locm,'')
	else set @locm=''
set @q_locm=rtrim(@locm)+'%'

declare @proprietati table(cont varchar(40), valuta varchar(20))
if @inValuta=1
	insert into @proprietati(cont, valuta)
	select rtrim(p.cod), rtrim(p.valoare) from proprietati p where p.tip='CONT' and p.cod_proprietate='INVALUTA' and isnull(p.valoare,'')<>'' and (@valuta='' or p.Valoare=@valuta)

select @CCont=isnull(@CCont,'')--+'%'
declare @cConturi table (cont varchar(50))
if @cCont<>''
	insert into @cConturi(cont)
		select cont from arbconturi(@cCont)

select c.subunitate, c.cont, c.denumire_cont, c.cont_parinte, c.tip_cont, c.are_analitice, p.valuta
	into #conturi
from conturi c 
left join @cConturi a on a.cont=c.cont
left join @proprietati p on c.Cont=p.cont
where /*c.cont like @ccont and*/ c.Subunitate=@subunitate
	and (@cCont='' or a.cont is not null) --and i.cont like RTrim(@cCont)+'%'
	and (@inValuta=0 or p.cont is not null)

declare @filtrefRulaje xml
select @filtrefRulaje=(select @indicator indicator for xml raw)

declare @grlm bit, @grindbug bit
select	@grlm=(case when @subtotaluri=2 then 1 else 0 end)
		,@grindbug=(case when @subtotaluri=3 then 1 else 0 end)
if object_id('tempdb..#pRulajeConturi_t') is not null
	drop table #pRulajeConturi_t
create table #pRulajeConturi_t (Subunitate varchar(10) default 1)
exec pRulajeConturi_tabela

if @invaluta=1
exec pRulajeConturi @nivelPlanContabil=1, @ccont=@ccont, @cValuta='valuta', @dData=@DataJos, @cLM=@q_locm, @parxml=@filtrefRulaje, @grlm=@grlm, @grindbug=@grindbug
--else*/
exec pRulajeConturi @nivelPlanContabil=1, @ccont=@ccont, @cValuta='', @dData=@DataJos, @cLM=@q_locm, @parxml=@filtrefRulaje, @grlm=@grlm, @grindbug=@grindbug
--select * from #pRulajeConturi_t
if @subtotaluri>1
	delete t from #pRulajeConturi_t t
		where nivel=2 and exists (select 1 from #pRulajeConturi_t t1 where t1.cont_parinte=t.cont)
		or nivel=1 and not exists (select 1 from #pRulajeConturi_t t1 where t1.cont_parinte=t.cont)

select max(co.valuta) valuta, max(c.Are_analitice) Are_analitice, c.Cont, max(c.Cont_parinte) Cont_parinte,
		max(c.Denumire_cont) Denumire_cont, max(c.Tip_cont) Tip_cont, sum(c.suma_credit) suma_credit,
		sum(c.suma_debit) suma_debit, sum(c.suma_credit_lei) suma_credit_lei,
		sum(c.suma_debit_lei) suma_debit_lei,
		(case max(c.tip_cont) when 'A' then sum(c.suma_debit_lei) when 'P' then 0 else (case when sum(c.suma_debit_lei)>0 then sum(c.suma_debit_lei) else 0 end) end) sold_deb, 
		(case max(c.tip_cont) when 'P' then sum(c.suma_credit_lei) when 'A' then 0 else (case when sum(c.suma_credit_lei)>0 then sum(c.suma_credit_lei) else 0 end) end) sold_cred, 
		(case max(c.tip_cont) when 'A' then sum(c.suma_debit_valuta) when 'P' then 0 else (case when sum(c.suma_debit_valuta)>0 then sum(c.suma_debit_valuta) else 0 end) end) sold_deb_valuta, 
		(case max(c.tip_cont) when 'P' then sum(c.suma_credit_valuta) when 'A' then 0 else (case when sum(c.suma_credit_valuta)>0 then sum(c.suma_credit_valuta) else 0 end) end) sold_cred_valuta,
		c.loc_de_munca, c.indbug
	into #solduri from
(
select valuta, f.Are_analitice, f.Cont, f.Cont_parinte, f.Denumire_cont, f.Tip_cont, f.suma_credit,
	f.suma_debit, suma_credit as suma_credit_lei, suma_debit as suma_debit_lei, loc_de_munca, indbug,
	convert(decimal(15,3),0) suma_credit_valuta, convert(decimal(15,3),0) suma_debit_valuta
	from #pRulajeConturi_t f
	where f.valuta=''
	union all
select valuta, f.Are_analitice, f.Cont, f.Cont_parinte, f.Denumire_cont, f.Tip_cont, f.suma_credit,
	f.suma_debit, 0 as suma_credit_lei, 0 as suma_debit_lei, loc_de_munca, indbug,
	convert(decimal(15,3),suma_credit) suma_credit_valuta, convert(decimal(15,3),suma_debit) suma_debit_valuta
	from #pRulajeConturi_t f
	where f.valuta<>''
)c	inner join #conturi co on co.Cont=c.Cont
	group by c.Cont, c.loc_de_munca, c.indbug

-- #solduri e bun si pentru filtrare
	-- filtrarea locurilor de munca pe utilizatori
declare @utilizator varchar(20)
select @utilizator=dbo.fiautilizator('')
declare @LmUtiliz table(valoare varchar(200))
insert into @LmUtiliz(valoare)
	select cod from lmfiltrare l where l.utilizator=@utilizator
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)

declare @bugetari bit
select @bugetari=val_logica from par where tip_parametru='GE' and parametru='bugetari'

create table #prelExplicatii(cont varchar(40), denumire_cont varchar(500), cont_parinte varchar(40), tip_document varchar(20),
	numar_document varchar(20), data datetime, cont_debitor varchar(40), cont_creditor varchar(40), suma_deb decimal(18,2),
	suma_cred decimal(18,2), sold_deb decimal(18,2), sold_cred decimal(18,2), suma_deb_valuta decimal(18,2),
	suma_cred_valuta decimal(18,2), sold_deb_valuta decimal(18,2), sold_cred_valuta decimal(18,2), explicatii varchar(500),
	numar varchar(20), jurnal varchar(20), ID varchar(2), subtotal varchar(1000), tip_cont varchar(20), are_analitice bit, are_rulaje bit, valuta varchar(20),
	numar_pozitie varchar(100) default 0)

insert into #prelExplicatii(cont, denumire_cont, cont_parinte, tip_document, numar_document, data, cont_debitor, cont_creditor,
	suma_deb, suma_cred, sold_deb, sold_cred, suma_deb_valuta, suma_cred_valuta, sold_deb_valuta,
	sold_cred_valuta, explicatii, numar, jurnal, ID, subtotal, tip_cont, are_analitice, are_rulaje, valuta, numar_pozitie)
	select rtrim(cont_debitor) as cont, isnull(rtrim(c.denumire_cont), '') as denumire_cont, isnull(c.cont_parinte, '') as cont_parinte, tip_document, 
		(case 
			when tip_document='PI' and len(rtrim(explicatii))-len(replace(rtrim(explicatii),' ',''))>=2 and explicatii not like 'N:%' then substring(explicatii,4,CHARINDEX(' ',explicatii,CHARINDEX(' ',explicatii,1)+1)-3) 
			when tip_document='PI' and explicatii like 'N:%' and CHARINDEX(',',explicatii)>5 then substring(explicatii,6,CHARINDEX(',',explicatii)-6)
			else a.numar_document end) as numar_document,
		a.data, cont_debitor, cont_creditor, 
		a.suma as suma_deb, 0 as suma_cred, 0 as sold_deb, 0 as sold_cred, 
		a.Suma_valuta as suma_deb_valuta, 0 as suma_cred_valuta, 0 as sold_deb_valuta, 0 as sold_cred_valuta, (case when @bugetari=1 then isnull(rtrim(a.indbug),'') else '' end)+' '+a.explicatii,
		(case when tip_document='PI' then str(a.numar_pozitie,13) else numar_document end) as numar, a.jurnal, left(a.explicatii,2) as ID,
		(case @subtotaluri when 1 then a.jurnal
				when 2 then a.loc_de_munca
				when 3 then a.indbug
			else '' end) as subtotal,
		isnull(c.tip_cont, '') as tip_cont, isnull(c.are_analitice, 0) as are_analitice, 0 as are_rulaje, c.valuta, a.numar_pozitie
	from pozincon a 
		inner join #conturi c on c.subunitate=a.subunitate and a.cont_debitor=c.cont/**	partea de debit	*/
	where a.Subunitate=@subunitate and a.data between @DataJos and @DataSus and 
		a.Loc_de_munca like @q_locm and
		(@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
		and c.Are_analitice=0
		and (@indicator is null or a.indbug like @indicator)
union all
	select rtrim(cont_creditor) as cont, isnull(rtrim(c.denumire_cont), '') as denumire_cont, isnull(c.cont_parinte, '') as cont_parinte, tip_document,
		(case 
			when tip_document='PI' and len(rtrim(explicatii))-len(replace(rtrim(explicatii),' ',''))>=2 and explicatii not like 'N:%' then substring(explicatii,4,CHARINDEX(' ',explicatii,CHARINDEX(' ',explicatii,1)+1)-3) 
			when tip_document='PI' and explicatii like 'N:%' and CHARINDEX(',',explicatii)>5 then substring(explicatii,6,CHARINDEX(',',explicatii)-6)
			else a.numar_document end) as numar_document,
		a.data, cont_debitor, cont_creditor, 
		0, a.suma, 0 as sold_deb, 0 as sold_cred,
		0, a.Suma_valuta, 0 as sold_deb, 0 as sold_cred, (case when @bugetari=1 then isnull(rtrim(a.indbug),'') else '' end)+' '+a.explicatii,
		(case when tip_document='PI' then str(a.numar_pozitie,13) else numar_document end) as numar, 
			a.jurnal, left(a.explicatii,2), 
			(case @subtotaluri when 1 then a.jurnal
				when 2 then a.loc_de_munca
				when 3 then a.indbug
			else '' end) as subtotal,
		isnull(c.tip_cont, '') as tip_cont, isnull(c.are_analitice, 0) as are_analitice, 0 as are_rulaje, c.valuta, a.numar_pozitie
	from pozincon a inner join #conturi c on c.subunitate=a.Subunitate and a.cont_creditor=c.cont	/**	partea de credit	*/
	where a.Subunitate=@subunitate and a.data between @DataJos and @DataSus and 
		a.Loc_de_munca like @q_locm
		and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
		and c.Are_analitice=0
		and (@indicator is null or a.indbug like @indicator)

	--> determin rulajele pentru fiecare cont cu analitice (din conturile care nu au analitice):
	;with x (cont, parinte)	--> determin componentele fara analitice care au rulaje ale fiecarui sintetic
	as
	(	select cont, cont_parinte from #conturi x where x.Are_analitice=0 --and  x.cont like '302%' 
		union all
		select x.cont, c.cont_parinte from #conturi c inner join x on c.Cont=x.parinte and c.cont<>x.cont and c.cont_parinte<>''
	)
	select x.parinte cont,
			sum(p.suma_deb) suma_deb, sum(p.suma_cred) suma_cred, sum(p.suma_deb) suma_deb_valuta, sum(p.suma_cred) suma_cred_valuta
		into #componenteConturi 
		from #prelExplicatii p inner join x on p.cont=x.cont
	group by x.parinte

	--> inserare date pentru conturile cu analitice
insert into #prelExplicatii(cont, denumire_cont, cont_parinte, tip_document, numar_document, data, cont_debitor, cont_creditor,
	suma_deb, suma_cred, sold_deb, sold_cred, suma_deb_valuta, suma_cred_valuta, sold_deb_valuta,
	sold_cred_valuta, explicatii, numar, jurnal, ID, subtotal, tip_cont, are_analitice, are_rulaje, valuta)
	select rtrim(s.cont), rtrim(denumire_cont), cont_parinte, '', '', '01/01/1901', '', '', 
		c.suma_deb, c.suma_cred,
		sold_deb, 
		sold_cred, 
		c.suma_deb_valuta, c.suma_cred_valuta,
		sold_deb_valuta, 		sold_cred_valuta,
		'', '', '', '', (case @subtotaluri --when 1 then a.jurnal
				when 2 then s.loc_de_munca
				when 3 then s.indbug
			else '' end) as subtotal, tip_cont, are_analitice,
		(case when @CuSoldRulaj=1 and not exists (select 1 from rulaje r where r.subunitate=@subunitate and r.cont=s.cont and r.loc_de_munca=s.loc_de_munca and r.indbug=s.indbug
				and r.data=@EOMDataSus and (r.rulaj_debit<>0 or r.rulaj_credit<>0))
			then 0 else 1 end) as are_rulaje,
		s.valuta
	from #solduri s left join #componenteConturi c on s.Cont=c.cont
	where (@valuta='' or s.valuta<>'')
--create index ordine on #prelexplicatii(cont, subtotal, data)

select p.cont, p.denumire_cont, p.cont_parinte, p.tip_document, p.numar_document, p.data, p.cont_debitor, p.cont_creditor,
	p.suma_deb, p.suma_cred, p.sold_deb, p.sold_cred, p.suma_deb_valuta, p.suma_cred_valuta, p.sold_deb_valuta,
	p.sold_cred_valuta, rtrim(p.explicatii)+isnull(' (f '+nullif(rtrim(d.factura),'')+')' ,'') explicatii,
	p.numar, p.jurnal, p.ID, p.subtotal, p.tip_cont, p.are_analitice, p.are_rulaje, p.valuta, p.numar_pozitie
into #final
from #prelExplicatii p 
	--left join doc d on d.subunitate=@subunitate and d.tip=p.tip_document and d.numar=p.numar and d.Data=p.data
	outer apply (select top 1 d.factura from doc d where d.subunitate=@subunitate and d.tip=p.tip_document and d.numar=p.numar and d.Data=p.data) d
		-->  "cross apply" pentru view-uri din baze de date (ahem dafora ahem) unde sunt sanse sa se repete acelasi nr doc + data + tip + subunitate
--order by cont, subtotal, data

if exists (select 1 from sys.objects where name='rapFisaContului_completareSP')
	exec rapFisaContului_completareSP @parXML=@xml

insert into #fisa(cont, denumire_cont, cont_parinte, tip_document, numar_document, data, cont_debitor, cont_creditor, suma_deb, suma_cred, sold_deb
		,sold_cred, suma_deb_valuta, suma_cred_valuta, sold_deb_valuta, sold_cred_valuta, explicatii, numar, jurnal, ID, subtotal, tip_cont, are_analitice
		,are_rulaje, valuta, numar_pozitie)
select cont, denumire_cont, cont_parinte, tip_document, numar_document, data, cont_debitor, cont_creditor, isnull(suma_deb,0), isnull(suma_cred,0),
	isnull(sold_deb,0), isnull(sold_cred,0), isnull(suma_deb_valuta,0), isnull(suma_cred_valuta,0), isnull(sold_deb_valuta,0), isnull(sold_cred_valuta,0), explicatii, numar, jurnal, ID,
	rtrim(isnull(subtotal,'')), tip_cont, convert(int,are_analitice) are_analitice, convert(int,are_rulaje) are_rulaje, valuta, numar_pozitie
from #final

declare @comanda_str varchar(max)
if @subtotaluri=1
begin
	set @comanda_str='
		update f set den_subtotal=rtrim(l.descriere)
		from #fisa f inner join jurnale l on f.subtotal=l.jurnal'
	exec (@comanda_str)
end

if @subtotaluri=2
begin
	set @comanda_str='
		update f set den_subtotal=rtrim(l.denumire)
		from #fisa f inner join lm l on f.subtotal=l.cod'
	exec (@comanda_str)
end

if @subtotaluri=3
begin
	set @comanda_str='
	update f set den_subtotal=rtrim(i.denumire)
	from #fisa f inner join indbug i on f.subtotal=i.indbug'
	exec (@comanda_str)
end

if @intabela<>1
begin
	--> alcatuiesc o tabela in care sa se calculeze toate cele necesara ca raportul (fisierul .rdl) sa fie cat mai simplu;
		--> din cauza calculului soldului rezulta complicatii la nivelurile superioare detaliilor, pe care le vom rezolva aici prin adaugarea de linii de totalizare;
		--> tot ce mai facem in raport este sa filtram pe nivelele inferioare (campul nivel<=nivel de grupare din raport) si pe nivelele superioare sa fie nivel=nivel
	--> detalii:
	select cont, denumire_cont, cont_parinte, tip_document, numar_document, data, cont_debitor, cont_creditor, suma_deb, suma_cred, sold_deb, sold_cred, suma_deb_valuta, suma_cred_valuta, sold_deb_valuta, sold_cred_valuta, explicatii, numar, jurnal, ID, subtotal, tip_cont,
		convert(int,are_analitice) are_analitice, convert(int,are_rulaje) are_rulaje, valuta,
			convert(int,0) as nivel, convert(decimal(15,2), 0) as sold_initial, convert(decimal(15,2), 0) as sold_final, den_subtotal, numar_pozitie,
			convert(decimal(15,2), 0) as sold_initial_valuta, convert(decimal(15,2), 0) as sold_final_valuta
		into #raport
		from #fisa
	order by abs(suma_deb), abs(suma_cred) -- cont, subtotal, data

	--> calcul subtotaluri + sold initial si sold final:
	insert into #raport(cont, denumire_cont, cont_parinte, tip_document, numar_document, data, cont_debitor, cont_creditor, suma_deb, suma_cred, sold_deb, sold_cred, suma_deb_valuta, suma_cred_valuta, sold_deb_valuta, sold_cred_valuta, explicatii, numar, jurnal, ID, subtotal, tip_cont, are_analitice, are_rulaje, valuta, nivel, sold_initial, sold_final, den_subtotal, numar_pozitie,sold_initial_valuta,sold_final_valuta)
	select cont, max(denumire_cont) denumire_cont, max(cont_parinte) cont_parinte, '' tip_document, '' numar_document, '' data, '' cont_debitor, '' cont_creditor,
		sum(suma_deb) suma_deb, sum(suma_cred) suma_cred, max(sold_deb) sold_deb, max(sold_cred) sold_cred,
		sum(suma_deb_valuta) suma_deb_valuta, sum(suma_cred_valuta) suma_cred_valuta, max(sold_deb_valuta) sold_deb_valuta, max(sold_cred_valuta) sold_cred_valuta, '' explicatii, '' numar, '' jurnal, max(id) ID, subtotal, max(tip_cont) tip_cont,
		max(are_analitice) are_analitice, 0 are_rulaje, max(valuta) valuta,
		1 nivel,
		(case when @subtotaluri=1 then 0 else sum(sold_deb)-sum(sold_cred) end) sold_initial,	--> pe jurnale = @subtotaluri=1 nu apar solduri (sau ar trebui?)
			(case when @subtotaluri=1 then 0 else sum(suma_deb)-sum(suma_cred)+sum(sold_deb)-sum(sold_cred) end) sold_final
		,max(den_subtotal), 0
		,convert(decimal(15,2), (case when @subtotaluri=1 then 0 else sum(sold_deb_valuta)-sum(sold_cred_valuta) end)) as sold_initial_valuta,
			convert(decimal(15,2), (case when @subtotaluri=1 then 0 else sum(suma_deb_valuta)-sum(suma_cred_valuta)+sum(sold_deb_valuta)-sum(sold_cred_valuta) end)) as sold_final_valuta
	from #raport r where nivel=0
	group by r.cont, r.subtotal
--/*
	--> calcul la nivel de cont; daca exista subtotaluri cu sold se vor lua soldurile de la nivel de subtotal:
	declare @nivel_inferior int
	set @nivel_inferior=0
	if @subtotaluri>1 set @nivel_inferior=1
	
	insert into #raport(cont, denumire_cont, cont_parinte, tip_document, numar_document, data, cont_debitor, cont_creditor, suma_deb, suma_cred, sold_deb, sold_cred, suma_deb_valuta, suma_cred_valuta, sold_deb_valuta, sold_cred_valuta, explicatii, numar, jurnal, ID, subtotal, tip_cont, are_analitice, are_rulaje, valuta, nivel, sold_initial, sold_final, den_subtotal, numar_pozitie,sold_initial_valuta,sold_final_valuta)
	select cont, max(denumire_cont) denumire_cont, max(cont_parinte) cont_parinte, '' tip_document, '' numar_document, '' data, '' cont_debitor, '' cont_creditor,
		sum(suma_deb) suma_deb,
		sum(suma_cred) suma_cred, sum(sold_deb) sold_deb, sum(sold_cred) sold_cred,
		sum(suma_deb_valuta) suma_deb_valuta, sum(suma_cred_valuta) suma_cred_valuta, sum(sold_deb_valuta) sold_deb_valuta, sum(sold_cred_valuta) sold_cred_valuta, '' explicatii, '' numar, '' jurnal, max(id) ID, '' subtotal, max(tip_cont) tip_cont,
		max(are_analitice) are_analitice, 0 are_rulaje, max(valuta) valuta,
		2 nivel,
		sum(sold_deb)-sum(sold_cred) sold_initial,
			sum(isnull(suma_deb,0))-sum(isnull(suma_cred,0))+sum(sold_deb)-sum(sold_cred) sold_final
		, '', 0
		,sum(sold_deb_valuta)-sum(sold_cred_valuta) sold_initial_valuta,
			sum(isnull(suma_deb_valuta,0))-sum(isnull(suma_cred_valuta,0))+sum(sold_deb_valuta)-sum(sold_cred_valuta) sold_final_valuta
	from #raport r where nivel=0
	group by r.cont
	
	--> calcul total:
	insert into #raport(cont, denumire_cont, cont_parinte, tip_document, numar_document, data, cont_debitor, cont_creditor, suma_deb, suma_cred, sold_deb, sold_cred, suma_deb_valuta, suma_cred_valuta, sold_deb_valuta, sold_cred_valuta, explicatii, numar, jurnal, ID, subtotal, tip_cont, are_analitice, are_rulaje, valuta, nivel, sold_initial, sold_final, den_subtotal, numar_pozitie,sold_initial_valuta,sold_final_valuta)
	select '' cont, '' denumire_cont, max(cont_parinte) cont_parinte, '' tip_document, '' numar_document, '' data, '' cont_debitor, '' cont_creditor,
		sum(case when are_analitice=0 then suma_deb else 0 end) suma_deb,
		sum(case when are_analitice=0 then suma_cred else 0 end) suma_cred, 0 sold_deb, 0 sold_cred,
		sum(suma_deb_valuta) suma_deb_valuta, sum(suma_cred_valuta) suma_cred_valuta, 0 sold_deb_valuta, 0 sold_cred_valuta, '' explicatii, '' numar, '' jurnal, max(id) ID, '' subtotal, 'B' tip_cont,
		max(are_analitice) are_analitice, 0 are_rulaje, max(valuta) valuta,
		3 nivel,
		sum(case when are_analitice=0 then sold_deb-sold_cred else 0 end) sold_initial,
			sum(case when are_analitice=0 then isnull(suma_deb,0)-isnull(suma_cred,0)+sold_deb-sold_cred
					else 0  end) sold_final
			,'',0
		,sum(case when are_analitice=0 then sold_deb_valuta-sold_cred_valuta else 0 end) sold_initial_valuta,
			sum(case when are_analitice=0 then isnull(suma_deb_valuta,0)-isnull(suma_cred_valuta,0)+sold_deb_valuta-sold_cred_valuta
					else 0  end) sold_final
	from #raport r where nivel=2

	if exists (select 1 from sys.objects where name='rapFisaContului_SP')
		 exec rapFisaContului_SP @parXML=@xml
	
	/* !!! select-ul final returneaza datele astfel incat raportul le grupeaza dupa numar pozitie, date document si conturi
		(chiar daca in procedura nu sunt grupate) !!!
	 --*/
	select 
		nivel
		--,sold_initial
		,(case when abs(sold_initial)<0.001 then '' when tip_cont='A' or tip_cont='B' and sold_initial>0 then convert(varchar(100),convert(money,sold_initial),-1)+' DB' else convert(varchar(100),convert(money,-sold_initial),-1)+' CR' end) as sold_initial
		,(case when abs(sold_final)<0.001 then '' when tip_cont='A' or tip_cont='B' and sold_final>0 then convert(varchar(100),convert(money,sold_final),-1)+' DB' else convert(varchar(100),convert(money,-sold_final),-1)+' CR' end) as sold_final
		,cont, denumire_cont, cont_parinte, tip_document, numar_document, data, cont_debitor, cont_creditor, suma_deb, suma_cred, sold_deb, sold_cred, suma_deb_valuta
		,suma_cred_valuta, sold_deb_valuta, sold_cred_valuta, explicatii, numar, jurnal, ID, subtotal, tip_cont, are_analitice, are_rulaje, valuta, den_subtotal, numar_pozitie
		,(case when abs(sold_initial_valuta)<0.001 then '' when tip_cont='A' or tip_cont='B' and sold_initial_valuta>0 then convert(varchar(100),convert(money,sold_initial_valuta),-1)+' DB' else convert(varchar(100),convert(money,-sold_initial_valuta),-1)+' CR' end) as sold_initial_valuta
		,(case when abs(sold_final_valuta)<0.001 then '' when tip_cont='A' or tip_cont='B' and sold_final_valuta>0 then convert(varchar(100),convert(money,sold_final_valuta),-1)+' DB' else convert(varchar(100),convert(money,-sold_final_valuta),-1)+' CR' end) as sold_final_valuta
	from #raport where nivel>=@centralizare
		order by nivel, cont, subtotal, data, cont_debitor, cont_creditor
		--*/
end
end try
begin catch
	select @eroare=error_message()+'('+ OBJECT_NAME(@@PROCID)+')'
end catch
--*/
if object_id('tempdb..#componenteConturi') is not null drop table #componenteConturi
if object_id('tempdb..#solduri') is not null drop table #solduri
if object_id('tempdb..#conturi') is not null drop table #conturi
if object_id('tempdb..#prelExplicatii') is not null drop table #prelExplicatii
if object_id('tempdb..#final') is not null drop table #final
if object_id('tempdb..#raport') is not null drop table #raport

if len(@eroare)>0
	select @eroare as denumire_cont, '<EROARE>' as cont
