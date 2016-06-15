--***
create procedure rapIntrariIesiriGrafic(@cod varchar(20)=null, @gestiune varchar(20)=null, @codintrare varchar(100)=null,
		@ctstoc varchar(100)=null, @datajos datetime, @datasus datetime,
		@Nivel1 varchar(2),	--> nivelul 1 de centralizare
		@tip_doc_str varchar(100),	--> tipurile de documente concatenate
		@locm varchar(20)=null, @tert varchar(20)=null, @contCor varchar(20)=null, @comanda varchar(20)=null,
		@indicator varchar(20)=null, @factura varchar(20)=null, @grafic bit=1)
as
declare @eroare varchar(2000)
begin try
	if @grafic=0 return
		/**	Pregatire filtrare pe proprietati utilizatori*/
	declare @eLmUtiliz int,@eGestUtiliz int
	declare @LmUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
	declare @GestUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
	insert into @LmUtiliz(valoare, cod_proprietate)
	select valoare, cod_proprietate from fPropUtiliz() where valoare<>'' and cod_proprietate='LOCMUNCA'
	set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
	insert into @GestUtiliz(valoare, cod_proprietate)
	select valoare, cod_proprietate from fPropUtiliz() where valoare<>'' and cod_proprietate='GESTIUNE'
	set @eGestUtiliz=isnull((select max(1) from @GestUtiliz),0)

	/**	Pregatire filtre:*/
	declare @flt_locm bit, @flt_tert bit, @flt_contCor bit, @flt_comanda bit, @flt_indicator bit, @flt_factura bit
	select	@flt_locm=(case when @locm is null then 0 else 1 end),
			@flt_tert=(case when @tert is null then 0 else 1 end),
			@flt_contCor=(case when @contCor is null then 0 else 1 end),
			@flt_comanda=(case when @comanda is null then 0 else 1 end),
			@flt_indicator=(case when @indicator is null then 0 else 1 end),
			@flt_factura=(case when @factura is null then 0 else 1 end),
		@locm=@locm+'%', @contCor=@contCor+'%', @indicator=@indicator+'%'

	/**	Selectare date:	*/
	create table #ptGrafic (grupare char(50),denumire char(150),valoare float)

	insert into #ptGrafic
	select top 10
		(case when @Nivel1='CO' then p.cod
		when @Nivel1='GE' then p.gestiune
		when @Nivel1='CM' then p.comanda 
		when @Nivel1='LU' then convert(varchar(3),month(p.data))
		when @Nivel1='LO' then p.loc_de_munca end),
		max((case when @Nivel1='CO' then n.denumire 
		when @Nivel1='GE' then ge.denumire_gestiune
		when @Nivel1='CM' then cm.descriere
		when @Nivel1='LU' then c.lunaalfa
		when @Nivel1='LO' then lm.denumire end)),
		sum(p.cantitate*p.pret_de_stoc) as valoare
	from pozdoc p
		left outer join nomencl n on p.cod=n.cod
		left outer join grupe g on n.grupa=g.grupa
		left outer join comenzi cm on p.comanda=cm.comanda
		left outer join gestiuni ge on p.gestiune=ge.cod_gestiune
		left outer join lm on p.loc_De_munca=lm.cod
		left outer join calstd c on p.data= c.data
	where charindex(','+rtrim(p.tip)+',',@tip_doc_str)>0 and
			(isnull(@codintrare,'')='' or p.cod=rtrim(ltrim(@codintrare))) 
			and (isnull(@ctstoc,'')='' or p.cont_de_stoc=rtrim(ltrim(@ctstoc))) 
			and (isnull(@gestiune,'')='' or rtrim(ltrim(@gestiune))=p.gestiune)
			and (isnull(@cod,'')='' or p.cod=rtrim(ltrim(@cod))) 
			and p.data between @datajos and @datasus
			and (@flt_locm=0 or p.loc_de_munca like @locm)
			and (@flt_tert=0 or p.Tert=@tert)
			and (@flt_contCor=0 or isnull((case when p.tip in('RS','RM','RP') then p.cont_factura else p.cont_corespondent end),'') like @contCor)
			and (@flt_comanda=0 or left(p.Comanda,20)=@comanda)
			and (@flt_indicator=0 or substring(p.Comanda,21,20) like @indicator)
			and	(@flt_factura=0 or p.Factura=@factura)
			and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=p.Loc_de_munca))
			and (@eGestUtiliz=0 or p.tip in ('AS','RS') or exists (select 1 from @GestUtiliz u where u.valoare=p.Gestiune))
	group by (case when @Nivel1='CO' then p.cod 
		when @Nivel1='GE' then p.gestiune
		when @Nivel1='CM' then p.comanda
		when @Nivel1='LU' then convert(varchar(3),month(p.data))
		when @Nivel1='LO' then p.loc_de_munca end)
	with rollup
	order by sum(p.cantitate*p.pret_de_stoc) desc

	--select * from #ptGrafic

	insert into #ptGrafic
	select 'Altii','Altii',sum((case when grupare is null then 1 else -1 end)*valoare) from #ptGrafic

	delete from #ptGrafic where grupare is null

	select * from #ptGrafic
end try
begin catch
	select @eroare=rtrim(error_message())+'( rapIntrariIesiriGrafic '+convert(varchar(20),error_line())+' )'
end catch

if object_id('tempdb..#ptGrafic') is not null drop table #ptGrafic
if len(@eroare)>0 raiserror(@eroare,16,1)