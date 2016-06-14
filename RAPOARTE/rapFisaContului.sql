/**	Procedura folosita de rapoartele CG/Contabilitate/Fisa contului	si Fisa contului in valuta*/
--***
if exists (select 1 from sysobjects where name='rapFisaContului' and xtype='P')
drop procedure rapFisaContului
GO
--***
create procedure [dbo].[rapFisaContului](@PeJurnale bit,@DataJos datetime,@DataSus datetime,
	@CCont nvarchar(4000),@CuSoldRulaj bit, @EOMDataSus datetime, @locm varchar(20),
	@valuta varchar(20) = null)
as
begin
/*
declare @PeJurnale bit,@DataJos datetime,@DataSus datetime,@CCont nvarchar(4000),@CuSoldRulaj bit,@EOMDataSus datetime, @locm varchar(20)
select @PeJurnale=0,@DataJos='2010-11-01 00:00:00',@DataSus='2010-11-30 00:00:00',@CCont=N'',@CuSoldRulaj=0,@EOMDataSus='2010-11-30 00:00:00'
--*/
set transaction isolation level read uncommitted
declare @subunitate char(9), @q_locm varchar(200), @eLmUtiliz int
select @subunitate=max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'

if (@valuta is null) set @valuta=''
select @CCont=isnull(@CCont,'')
if exists (select 1 from par where Tip_parametru='GE' and Parametru='rulajelm' and Val_logica=1)
	set @locm=ISNULL(@locm,'')
	else set @locm=''
set @q_locm=rtrim(@locm)+'%'
select max(valuta) valuta, max(c.Are_analitice) Are_analitice, c.Cont, max(c.Cont_parinte) Cont_parinte,
		max(c.Denumire_cont) Denumire_cont, max(c.Tip_cont) Tip_cont, sum(c.suma_credit) suma_credit,
		sum(c.suma_debit) suma_debit, sum(c.suma_credit_lei) suma_credit_lei,
		sum(c.suma_debit_lei) suma_debit_lei
	into #solduri from
(
select '' as valuta, f.Are_analitice, f.Cont, f.Cont_parinte, f.Denumire_cont, f.Tip_cont, f.suma_credit,
	f.suma_debit, 0 as suma_credit_lei, 0 as suma_debit_lei
	from dbo.frulajeconturi(1,@ccont, @valuta, @DataJos, '',@q_locm, default) f where @valuta<>'' union all
select @valuta as valuta, fl.Are_analitice, fl.Cont, fl.Cont_parinte, fl.Denumire_cont, fl.Tip_cont, 0 suma_credit, 0 suma_debit, 
		fl.suma_credit suma_credit_lei, fl.suma_debit suma_debit_lei
	from dbo.frulajeconturi(1,@ccont, '', @DataJos, '',@q_locm, default) fl
)c	group by c.Cont
-- #solduri e bun si pentru filtrare
	-- filtrarea locurilor de munca pe utilizatori
declare @LmUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
insert into @LmUtiliz(valoare, cod_proprietate)
select * from fPropUtiliz() where valoare<>'' and cod_proprietate='LOCMUNCA'
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)

select cont_debitor as cont, isnull(c.denumire_cont, '') as denumire_cont, isnull(c.cont_parinte, '') as cont_parinte, tip_document, 
(case when tip_document<>'PI' then numar_document else isnull((select top 1 p.numar from pozplin p where p.subunitate=a.subunitate and p.cont=a.cont_debitor and p.data=a.data and p.numar_pozitie=a.numar_pozitie), isnull((select top 1 p.numar from pozplin p where p.subunitate=a.subunitate and p.cont=(case when left(a.explicatii,1)='I' then a.cont_debitor else a.cont_creditor end) and p.data=a.data and p.numar_pozitie=a.numar_pozitie), numar_document)) end) as numar_document,
          data, cont_debitor, cont_creditor, 
          suma as suma_deb, 0 as suma_cred, 0 as sold_deb, 0 as sold_cred, 
          Suma_valuta as suma_deb_valuta, 0 as suma_cred_valuta, 0 as sold_deb_valuta, 0 as sold_cred_valuta, 
			explicatii,
          (case when tip_document='PI' then str(numar_pozitie,13) else numar_document end) as numar, jurnal, left(explicatii,2) as ID, (case when @PeJurnale=1 then jurnal else '' end) as jurn_ord,
          isnull(c.tip_cont, '') as tip_cont, isnull(c.are_analitice, 0) as are_analitice, 0 as are_rulaje, a.valuta
          from pozincon a left outer join conturi c on c.subunitate=@subunitate and a.cont_debitor=c.cont	/**	partea de debit	*/
          where a.subunitate=c.subunitate and a.data between @DataJos and @DataSus and 
			a.Loc_de_munca like @q_locm and
			(isnull(@valuta,'')='' /*is null*/ or a.valuta=@valuta) and
			(@CCont='' or exists (select 1 from #solduri ac where ac.cont=a.cont_debitor))
				and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
			and (@valuta='' or abs(Suma_valuta)<>0)

          union all
          select cont_creditor as cont, isnull(c.denumire_cont, '') as denumire_cont, isnull(c.cont_parinte, '') as cont_parinte, tip_document,
          (case when tip_document<>'PI' then numar_document else isnull((select top 1 p.numar from pozplin p where p.subunitate=a.subunitate and p.cont=a.cont_debitor and p.data=a.data and p.numar_pozitie=a.numar_pozitie), isnull((select top 1 p.numar from pozplin p where p.subunitate=a.subunitate and p.cont=(case when left(a.explicatii,1)='I' then a.cont_debitor else a.cont_creditor end) and p.data=a.data and p.numar_pozitie=a.numar_pozitie), numar_document)) end) as numar_document,
          data, cont_debitor, cont_creditor, 
		  0, suma, 0 as sold_deb, 0 as sold_cred,
          0, Suma_valuta, 0 as sold_deb, 0 as sold_cred,
          explicatii,
          (case when tip_document='PI' then str(numar_pozitie,13) else numar_document end) as numar, jurnal, left(explicatii,2), (case when @PeJurnale=1 then jurnal else '' end),
          isnull(c.tip_cont, '') as tip_cont, isnull(c.are_analitice, 0) as are_analitice, 0 as are_rulaje, a.valuta
          from pozincon a left outer join conturi c on c.subunitate=@subunitate and a.cont_creditor=c.cont	/**	partea de credit	*/
          where a.subunitate=c.subunitate and a.data between @DataJos and @DataSus and 
			a.Loc_de_munca like @q_locm and
			(@CCont='' or exists (select 1 from #solduri ac where ac.cont=a.cont_creditor))
			and (isnull(@valuta,'')='' or a.valuta=@valuta) 
			and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
			and (@valuta='' or abs(Suma_valuta)<>0)
          union all						/**	soldurile:	*/
          select cont, denumire_cont, cont_parinte, '', '', '01/01/1901', '', '', 
          0, 0,
			(case tip_cont when 'A' then s.suma_debit_lei when 'P' then 0 else (case when s.suma_debit_lei>0 then s.suma_debit_lei else 0 end) end), 
			(case tip_cont when 'P' then s.suma_credit_lei when 'A' then 0 else (case when s.suma_credit_lei>0 then s.suma_credit_lei else 0 end) end), 
		  0, 0,
			(case tip_cont when 'A' then s.suma_debit when 'P' then 0 else (case when s.suma_debit>0 then s.suma_debit else 0 end) end), 
			(case tip_cont when 'P' then s.suma_credit when 'A' then 0 else (case when s.suma_credit>0 then s.suma_credit else 0 end) end), 
'', '', '', '', '', tip_cont, are_analitice,
(case when @CuSoldRulaj=1 and not exists (select 1 from rulaje r where r.subunitate=@subunitate and r.cont=s.cont and r.data=@EOMDataSus and (r.rulaj_debit<>0 or r.rulaj_credit<>0)) then 0 else 1 end) as are_rulaje
		, s.valuta
          from #solduri s
			where (@valuta='' or valuta<>'')
			order by cont, jurn_ord, data
          

if object_id('tempdb..#solduri') is not null drop table #solduri
end
go
/*
declare @PeJurnale bit,@DataJos datetime,@DataSus datetime,@CCont nvarchar(4000),@CuSoldRulaj bit,@EOMDataSus datetime, @locm varchar(20)
select @PeJurnale=0,@DataJos=''2010-11-01 00:00:00'',@DataSus=''2010-11-30 00:00:00'',@CCont=N'''',@CuSoldRulaj=0,@EOMDataSus=''2010-11-30 00:00:00''
--*/
declare	@PeJurnale bit,@DataJos datetime,@DataSus datetime,@CCont nvarchar(5),@CuSoldRulaj bit,@locm nvarchar(4000)
select @PeJurnale=0,@DataJos='2012-09-01 00:00:00',@DataSus='2012-09-30 00:00:00',@CCont=N'707.0',@CuSoldRulaj=0,@locm=NULL

declare @EOMDataSus datetime
set @EOMDataSus=dateadd(D,-day(dateadd(M,1,@DataSus)),dateadd(M,1,@DataSus))
exec rapFisaContului @PeJurnale=@PeJurnale, @DataJos=@DataJos, @DataSus=@DataSus, @CCont=@CCont, @CuSoldRulaj=@CuSoldRulaj, @EOMDataSus=@EOMDataSus, @locm=@locm
