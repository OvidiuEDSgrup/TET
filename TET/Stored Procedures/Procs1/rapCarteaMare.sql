--***
create procedure rapCarteaMare (@DataJos datetime,@DataSus datetime,@CCont varchar(40),@CuSoldRulaj int=2,@locm varchar(20))
as
	/*	Cartea mare
	declare @DataJos datetime,@DataSus datetime,@CCont nvarchar(4000),@CuSoldRulaj int,@locm nvarchar(4000)
	select @DataJos='2009-11-01 00:00:00',@DataSus='2011-11-30 00:00:00'--,@CCont='101%'
			,@CuSoldRulaj=2
			--,@locm='10%'

	--*/
--exec fainregistraricontabile @datasus=@DataSus
set transaction isolation level read uncommitted
if object_id('tempdb..#date') is not null drop table #date
if object_id('tempdb..#LmUtiliz') is not null drop table #LmUtiliz
if object_id('tempdb..#solduri') is not null drop table #solduri
declare @eroare varchar(500)
begin try
	
	declare @utilizator varchar(20), @subunitate varchar(9),@EOMDataSus datetime, @eLmUtiliz int
	select	@EOMDataSus=DateAdd(day, -1, DateAdd(MONTH, Month(@DataSus), DateAdd(Year, Year(@DataSus)-1901, '1901-1-1')))
	set @subunitate=(select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO')

	select @utilizator=dbo.fIaUtilizator('')
	select cod as valoare into #LmUtiliz from lmfiltrare where utilizator=@utilizator
	set @eLmUtiliz=isnull((select max(1) from #LmUtiliz),0)

	select @CCont=isnull(@CCont,'')+'%'
	if exists (select 1 from par where Tip_parametru='GE' and Parametru='rulajelm' and Val_logica=1)
		set @locm=ISNULL(@locm,'')
		else set @locm=''
	set @locm=@locm+'%'
	
	if object_id('tempdb..#pRulajeConturi_t') is not null
	drop table #pRulajeConturi_t
	create table #pRulajeConturi_t (Subunitate varchar(10) default 1)
	exec pRulajeConturi_tabela
	exec pRulajeConturi @nivelPlanContabil=1, @ccont=@ccont, @cValuta='', @dData=@DataJos, @cLM=@locm
	select * into #solduri from #prulajeconturi_t s where left(s.Cont,1) not in ('8','9')
--	select * into #solduri from dbo.fRulajeConturi(1,@ccont, '', @DataJos, '',@locm, default, null) s where left(s.Cont,1) not in ('8','9')
	select @eroare=(select top 1 rtrim(cont)+' - '+lower(rtrim(s.Denumire_cont)) from #solduri s where s.Denumire_cont='Cont configurat gresit! (Nu are analitice!)')
	if len(@eroare)>0 raiserror(@eroare,16,1)
	
			--> conturi cu rulaj debit:
	select cont_debitor as cont, isnull(c.denumire_cont, '') as denumire_cont, isnull(c.cont_parinte, '') as cont_parinte, tip_document,
			(case when tip_document<>'PI' then numar_document 
				else isnull((select top 1 p.numar from pozplin p where p.subunitate=a.subunitate and p.cont=a.cont_debitor and 
								p.data=a.data and p.numar_pozitie=a.numar_pozitie), 
								isnull((select top 1 p.numar from pozplin p 
									where p.subunitate=a.subunitate and p.cont=(case when left(a.explicatii,1)='I' then a.cont_debitor else a.cont_creditor end)
									and p.data=a.data and p.numar_pozitie=a.numar_pozitie), numar_document)) end) as numar_document,
			  data, cont_debitor, cont_creditor, suma as suma_deb, 0 as suma_cred, 0 as sold_deb, 0 as sold_cred, explicatii,
			  (case when tip_document='PI' then str(numar_pozitie,13) else numar_document end) as numar, jurnal, left(explicatii,2) as ID, /*(case when @PeJurnale=1 then jurnal else '' end) as jurn_ord,*/
			  isnull(c.tip_cont, '') as tip_cont, isnull(c.are_analitice, 0) as are_analitice, 0 as are_rulaje, 'CR: '+cont_creditor as grupare,isnull((select denumire_cont from conturi cc where cc.subunitate=subunitate and cc.cont=cont_creditor),'') as den_grupare, 
			  0 as s_db_rulaje, 0 as s_cr_rulaje /*, (case when len(ltrim(rtrim(cont_creditor)))>3 and @ContSint=1 then 'CR: '+left(cont_creditor,3) else '' end) as pe_sint*/,/*0 as are_rulaje_sau_sold,*/0 as rulaj_db_sint, 0 as rulaj_cr_sint,
			  0 as nivel
			  into #date
			  from pozincon a left outer join conturi c on c.subunitate=a.subunitate and 
			  a.cont_debitor=c.cont
			  where a.subunitate=@subunitate and a.data between @DataJos and @DataSus and (((@CCont='' and left(a.cont_debitor,1) not in ('8','9') and left(a.cont_creditor,1) not in ('8','9')) or 
			  (@CCont<>'' and exists (select 1 from #solduri ac where ac.cont=a.cont_debitor))))
				and (@eLmUtiliz=0 or exists (select 1 from #LmUtiliz u where u.valoare=a.Loc_de_munca))
				and a.Loc_de_munca like @locm

	union all 
			--> conturi cu rulaj credit:
	select cont_creditor as cont, isnull(c.denumire_cont, '') as denumire_cont, isnull(c.cont_parinte, '') as cont_parinte, tip_document,
	(case when tip_document<>'PI' then numar_document else isnull((select top 1 p.numar from pozplin p where p.subunitate=a.subunitate and p.cont=a.cont_debitor and p.data=a.data and p.numar_pozitie=a.numar_pozitie), 
			  isnull((select top 1 p.numar from pozplin p where p.subunitate=a.subunitate and p.cont=(case when left(a.explicatii,1)='I' then a.cont_debitor else a.cont_creditor end) and p.data=a.data and p.numar_pozitie=a.numar_pozitie), numar_document)) end) as numar_document,
			  data, cont_debitor, cont_creditor, 0, suma, 0 as sold_deb, 0 as sold_cred, explicatii,
			  (case when tip_document='PI' then str(numar_pozitie,13) else numar_document end) as numar, jurnal, left(explicatii,2), /*(case when @PeJurnale=1 then jurnal else '' end),*/
			  isnull(c.tip_cont, '') as tip_cont, isnull(c.are_analitice, 0) as are_analitice, 0 as are_rulaje, 'DB: '+cont_debitor as grupare, isnull((select denumire_cont from conturi cc where cc.subunitate=subunitate and cc.cont=cont_debitor),'') as den_grupare,
			  0,0 /*, (case when len(ltrim(rtrim(cont_creditor)))>3 and @ContSint=1 then 'DB: '+left(cont_debitor,3) else '' end)*/, /*0,*/ 0, 0,
			  0 as nivel
			  from pozincon a left outer join conturi c on c.subunitate=a.subunitate and 
			  a.cont_creditor=c.cont
			  where a.subunitate=@subunitate and a.data between @DataJos and @DataSus and 
			  (((@CCont='' and left(a.cont_creditor,1) not in ('8','9') and left(a.Cont_debitor,1) not in ('8','9')) or (@CCont<>'' and 
			  exists (select 1 from #solduri ac where ac.cont=a.cont_creditor))))
			  and (@eLmUtiliz=0 or exists (select 1 from #LmUtiliz u where u.valoare=a.Loc_de_munca))
			  and a.Loc_de_munca like @locm
			--> conturi fara rulaj:
	union all
	select c.cont, c.denumire_cont, c.cont_parinte, '', '', '01/01/1901', '', '', 0, 0,
		(case c.tip_cont when 'A' then s.suma_debit when 'P' then 0 
			else (case when s.suma_debit>0 then s.suma_debit else 0 end) end) as sold_cred, 
		(case c.tip_cont when 'P' then s.suma_credit when 'A' then 0 
			else (case when s.suma_credit>0 then s.suma_credit else 0 end) end) as sold_deb,
		'', '', '', '', /*'',*/ c.tip_cont, c.are_analitice, 
		(case when @CuSoldRulaj=1 and not exists (select 1 from rulaje r where r.subunitate=c.subunitate and r.cont=c.cont and r.data between dbo.eom(@datajos) and @EOMDataSus and (r.rulaj_debit<>0 or r.rulaj_credit<>0))
			then 0 else 1 end) as are_rulaje,'','',
		--0,0,0,0
		isnull((select sum(rulaj_debit) from rulaje r1 where r1.subunitate=c.subunitate and r1.cont=c.cont and r1.data between dbo.eom(@datajos) and @EOMDataSus and r1.valuta='' and r1.Loc_de_munca like @locm
			and (@eLmUtiliz=0 or exists (select 1 from #LmUtiliz u where u.valoare=r1.Loc_de_munca))),0),
		isnull((select sum(rulaj_credit) from rulaje r1 where r1.subunitate=c.subunitate and r1.cont=c.cont and r1.data between dbo.eom(@datajos) and @EOMDataSus and r1.valuta='' and r1.Loc_de_munca like @locm
			and (@eLmUtiliz=0 or exists (select 1 from #LmUtiliz u where u.valoare=r1.Loc_de_munca))),0)/*,''*/,
		(case when c.cont_parinte='' then isnull(
				(select sum(rulaj_debit) from rulaje r1 where r1.subunitate=c.subunitate and r1.cont=c.cont and r1.data between dbo.eom(@datajos) and @EOMDataSus and r1.valuta=''
						and (@locm is null or r1.Loc_de_munca like @locm+'%') and (@eLmUtiliz=0 or exists (select 1 from #LmUtiliz u where u.valoare=r1.Loc_de_munca))),0) else 0 end),
		(case when c.cont_parinte='' then isnull(
				(select sum(rulaj_credit) from rulaje r1 where r1.subunitate=c.subunitate and r1.cont=c.cont and r1.data between dbo.eom(@datajos) and @EOMDataSus and r1.valuta=''
						and (@locm is null or r1.Loc_de_munca like @locm+'%') and (@eLmUtiliz=0 or exists (select 1 from #LmUtiliz u where u.valoare=r1.Loc_de_munca))),0) else 0 end),
		2 as nivel
	from conturi c inner join #solduri s on c.Cont=s.cont
	where c.subunitate=@subunitate and left(c.cont,1) not in ('8','9')
	order by cont, grupare, data, Tip_document, numar_document, numar
	--*/
	if (@CuSoldRulaj=1)	--> daca e cazul se elimina randurile care nu au sume
	delete d
		from #date d inner join (select sum(abs(s.s_db_rulaje)+abs(s.s_cr_rulaje)+abs(s.sold_cred)+abs(s.sold_deb)+abs(s.suma_cred)+abs(s.suma_deb)) as suma, s.cont from #date s group by s.cont) s on d.cont=s.cont
		where not (isnull(s.suma,0)>0.005)
/*	create index indDate on #date(cont)
	--> identificare linii fara solduri
	update d set nivel=3 from #date d
		where nivel=2 and not exists (select 1 from #date dd where dd.cont=d.cont and dd.nivel=0)
*//*	
	select cont, denumire_cont, cont_parinte, tip_document, numar_document, data, cont_debitor, cont_creditor, suma_deb, suma_cred, sold_deb, sold_cred, explicatii, numar,
		jurnal, ID, tip_cont, are_analitice, are_rulaje, grupare, den_grupare, s_db_rulaje, s_cr_rulaje, rulaj_db_sint, rulaj_cr_sint
	from #date	--*/

--> conturi
	select '' cod_parinte, rtrim(cont) as cod,
		--cont, 
			rtrim(cont)+' - '+max(rtrim(denumire_cont)) denumire,
			--max(case when nivel=3 then else 0 end)
			/*max(case when d.tip_cont='A' or d.tip_cont='B' and d.sold_deb-d.sold_cred>0 
					then d.sold_deb-d.sold_cred else d.sold_cred-d.sold_deb end)*/
			max(d.sold_deb-d.sold_cred) sold_initial, 
			max(s_db_rulaje) s_db_rulaje, max(s_cr_rulaje) s_cr_rulaje, d.tip_cont tip_cont, '1901-1-1' data, 2 nivel,
			--max(case when nmivel=3 then else 0 end) sold_final, 
			max(case when d.tip_cont='A' or d.tip_cont='B' and d.sold_deb-d.sold_cred>0 then 1 else -1 end) debit, sum(d.rulaj_db_sint) rulaj_db_sint, sum(d.rulaj_cr_sint) rulaj_cr_sint,
			0 suma_debit, 0 suma_credit, '' explicatii, '' tip
		/*ont_parinte, tip_document, numar_document, data, cont_debitor, cont_creditor, suma_deb, suma_cred, sold_deb, sold_cred, explicatii, numar,
		jurnal, ID, tip_cont, are_analitice, are_rulaje, grupare, den_grupare, s_db_rulaje, s_cr_rulaje, rulaj_db_sint, rulaj_cr_sint*/
	from #date d where nivel>=2 group by cont, tip_cont
	union all
-->		conturi corespondente
	select 
		max(rtrim(d.cont)) as cod_parinte, max(rtrim(d.cont))+'|'+rtrim(d.grupare),
		rtrim(d.grupare)+' - '+max(rtrim(d.den_grupare)) denumire, 0 sold_initial,
		0 s_db_rulaje, 0 s_cr_rulaje, d.tip_cont tip, '1901-1-1' data, 1 nivel,
		(case when d.tip_cont='A' or d.tip_cont='B' and max(d.sold_deb-d.sold_cred)>0 then 1 else -1 end) debit, 0 as rulaj_db_sint, 0 as rulaj_cr_sint,
		0 suma_debit, 0 suma_credit, '' explicatii, '' tip
		/*cont, denumire_cont, cont_parinte, tip_document, numar_document, data, cont_debitor, cont_creditor, suma_deb, suma_cred, sold_deb, sold_cred, explicatii, numar,
		jurnal, ID, tip_cont, are_analitice, are_rulaje, grupare, den_grupare, s_db_rulaje, s_cr_rulaje, rulaj_db_sint, rulaj_cr_sint,*/
	from #date d where grupare<>'' and nivel=0 group by d.grupare, d.tip_cont, d.cont
	union all
-->		detalii
	select 
		rtrim(d.cont)+'|'+rtrim(d.grupare), rtrim(d.cont)+'|'+rtrim(d.grupare)+'|'+rtrim(convert(varchar(20),d.data,102))+'|'+rtrim(d.tip_cont)+'|'+rtrim(d.numar) as cod,
		rtrim(d.numar) as denumire, 0 sold_initial,
		d.suma_deb s_db_rulaje, d.suma_cred s_cr_rulaje, d.tip_cont, d.data, 0 nivel,
		(case when d.tip_cont='A' or d.tip_cont='B' and d.sold_deb-d.sold_cred>0 then 1 else -1 end) debit, 0 rulaj_db_sint, 0 rulaj_cr_sint,
		suma_deb suma_debit, suma_cred suma_credit, rtrim(d.explicatii) explicatii, d.tip_document tip
		/*cont, denumire_cont, cont_parinte, tip_document, numar_document, data, cont_debitor, cont_creditor, suma_deb, suma_cred, sold_deb, sold_cred, explicatii, numar,
		jurnal, ID, tip_cont, are_analitice, are_rulaje, grupare, den_grupare, s_db_rulaje, s_cr_rulaje, rulaj_db_sint, rulaj_cr_sint*/
	from #date d where nivel=0
	order by nivel, cod
--	*/
end try
begin catch
	set @eroare=ERROR_MESSAGE()+'(rapCarteaMare)'
end catch

if len(@eroare)>0 --raiserror(@eroare,16,1)
	select '<EROARE>' as cod_parinte, @eroare as cod

if object_id('tempdb..#date') is not null drop table #date
if object_id('tempdb..#LmUtiliz') is not null drop table #LmUtiliz
if object_id('tempdb..#solduri') is not null drop table #solduri
