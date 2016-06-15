--***
create procedure rapAvize_grafic(@datajos datetime,@datasus datetime, @tert varchar(50)=null, @cod varchar(50)=null,
					@gestiune varchar(50)=null, @lm varchar(50)=null, @factura varchar(50)=null, @comanda varchar(50)=null,
				@Nivel1 varchar(2), @grafic bit=0, @grupaTerti varchar(20)=null)
				
--*/	/**	Pregatire filtrare pe proprietati utilizatori*/
as
	set transaction isolation level read uncommitted
	if @grafic=0 return
	declare @eLmUtiliz int,@eGestUtiliz int
	declare @LmUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
	declare @GestUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
	insert into @LmUtiliz(valoare, cod_proprietate)
	select valoare, cod_proprietate from fPropUtiliz() where valoare<>'' and cod_proprietate='LOCMUNCA'
	set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
	insert into @GestUtiliz(valoare, cod_proprietate)
	select valoare, cod_proprietate from fPropUtiliz() where valoare<>'' and cod_proprietate='GESTIUNE'
	set @eGestUtiliz=isnull((select max(1) from @GestUtiliz),0)
	declare @f_tert bit, @f_cod bit, @f_gestiune bit, @f_lm bit, @f_factura bit, @f_comanda bit, @f_grupaTerti bit
	select @f_tert=(case when @tert is null then 0 else 1 end),
		@f_cod=(case when @cod is null then 0 else 1 end),
		@f_gestiune=(case when @gestiune is null then 0 else 1 end),
		@f_lm=(case when @lm is null then 0 else 1 end),
		@f_factura=(case when @factura is null then 0 else 1 end),
		@f_comanda=(case when @comanda is null then 0 else 1 end),
		@f_grupaTerti=(case when @grupaTerti is null then 0 else 1 end),
		@lm=@lm+'%'
		
	create table #ptGrafic (grupare char(50),denumire char(500),valoare float)

	if (@grafic=1)
	begin
	insert into #ptGrafic
	select top 10
	(case when @Nivel1='CO' then p.cod
	when @Nivel1='GE' then p.gestiune
	when @Nivel1='TE' then p.tert 
	when @Nivel1='LU' then convert(varchar(3),month(p.data))
	when @Nivel1='LO' then p.loc_de_munca end),
	max((case when @Nivel1='CO' then n.denumire 
	when @Nivel1='GE' then ge.denumire_gestiune
	when @Nivel1='TE' then t.denumire
	when @Nivel1='LU' then c.lunaalfa
	when @Nivel1='LO' then lm.denumire end)),
	sum(p.cantitate*p.pret_vanzare) as valoare
	from pozdoc p
	left outer join nomencl n on p.cod=n.cod
	left outer join grupe g on n.grupa=g.grupa
	left outer join terti t on p.tert=t.tert
	left outer join gestiuni ge on p.gestiune=ge.cod_gestiune
	left outer join lm on p.loc_De_munca=lm.cod
	left outer join calstd c on p.data= c.data
	where p.tip in ('AP','AC','AS') and p.data between @datajos and @datasus 
	and (@f_tert=0 or p.tert=@tert or t.denumire like '%'+replace(isnull(@tert,' '),' ','%')+'%') 
	and (@f_cod=0 or p.cod=@cod or n.denumire like '%'+replace(isnull(@cod,' '),' ','%')+'%') and 
	(@f_gestiune=0 or p.gestiune=@gestiune) and (@f_lm=0 or lm.cod like @lm)
	and (p.factura = @factura or @f_factura=0) and (p.comanda = @comanda or @f_comanda=0)
	and (@f_grupaTerti=0 or t.Grupa=@grupaTerti)
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=p.Loc_de_munca))
	and (@eGestUtiliz=0 or exists (select 1 from @GestUtiliz u where u.valoare=p.Gestiune))
	group by (case when @Nivel1='CO' then p.cod 
	when @Nivel1='GE' then p.gestiune
	when @Nivel1='TE' then p.tert
	when @Nivel1='LU' then convert(varchar(3),month(p.data))
	when @Nivel1='LO' then p.loc_de_munca end)
	with rollup
	order by sum(p.cantitate*p.pret_vanzare) desc
	insert into #ptGrafic
	select 'Altii','Altii',sum((case when grupare is null then 1 else -1 end)*valoare) from #ptGrafic

	delete from #ptGrafic where grupare is null
	end
	select * from #ptGrafic
	drop table #ptGrafic