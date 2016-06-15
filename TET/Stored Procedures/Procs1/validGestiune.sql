create procedure validGestiune
as
begin try
	/** 
		Procedura valideaza set-uri de date: comanda din tabela #gestiuni(cod varchar(20), primitoare bit, data datetime)
		Se valideaza:
			- existenta in catalog		
			- blank
			- gestiuni invalidate pe o anumita perioada


		ATENTIE: daca se doreste ca utilizatorul sa aiba drept pe orice GESTIUNE ca gestiune PRIMITOARE este necesar parametrul
		insert into par values ('GE','PRIMALL','Toate gest. prim.',1,0,'')
	*/	

	declare @primall bit

	exec luare_date_par 'GE','PRIMALL',@primall OUTPUT, 0,''

	if left(cast(CONTEXT_INFO() as varchar),17)='specificebugetari'
		return

	declare 
		@userASiS varchar(100)
	set @userASiS=dbo.fIaUtilizator(null)

	if exists(select 1 from #gestiuni where cod='')
		raiserror('Gestiune necompletata!',16,1)
	
	IF exists(select 1 from #gestiuni g LEFT join gestiuni gg on g.cod=gg.Cod_gestiune where g.cod<>'' and gg.Cod_gestiune is NULL)
	begin
		declare
			@gest_err varchar(MAX)
		set @gest_err = ''
		select @gest_err = @gest_err + RTRIM(g.cod) + ',' from #gestiuni g LEFT join gestiuni gg on g.cod=gg.Cod_gestiune
			where g.cod<>'' and gg.Cod_gestiune is NULL
		set @gest_err = 'Gestiune inexistenta in catalog (' + left(@gest_err,LEN(@gest_err)-1) + ')!'
		raiserror(@gest_err,16,1)
	end
	
	/** 
		Verificarea restrictiilor utilizatorului pe anumite gestiuni si gestiuni primitoare
	*/
	select 
		valoare gestiune into #gestiuni_prop 
	from proprietati pr where pr.Tip='UTILIZATOR' and pr.Cod_proprietate='GESTIUNE' and pr.cod=@userASiS and valoare<>''
	declare
			@gestprop_err varchar(MAX)

	IF EXISTS(select * from #gestiuni g LEFT JOIN  #gestiuni_prop gg on g.cod=gg.gestiune where gg.gestiune IS NULL and ISNULL(g.primitoare,0)=0)
	and exists (select 1 from #gestiuni_prop)
	begin

		set @gestprop_err = ''
		select @gestprop_err = @gestprop_err + RTRIM(g.cod) + ',' from #gestiuni g LEFT JOIN  #gestiuni_prop gg on g.cod=gg.gestiune where gg.gestiune IS NULL and ISNULL(g.primitoare,0)=0
		set @gestprop_err = 'Nu aveti drepturi pe aceasta gestiune (' + left(@gestprop_err,LEN(@gestprop_err)-1) + ')!'
		raiserror(@gestprop_err,16,1)
	end

	select 
		valoare gestiune into #gestiuniprim_prop 
	from proprietati pr where pr.Tip='UTILIZATOR' and pr.Cod_proprietate in ('GESTPRIM','GESTIUNE') and pr.cod=@userASiS and valoare<>''

	IF EXISTS(select * from #gestiuni g LEFT JOIN  #gestiuniprim_prop gg on g.cod=gg.gestiune where gg.gestiune IS NULL and ISNULL(g.primitoare,0)=1)
	and exists (select 1 from #gestiuniprim_prop) and @primall = 0
	begin
		set @gestprop_err = ''
		select @gestprop_err = @gestprop_err + RTRIM(g.cod) + ',' from #gestiuni g LEFT JOIN  #gestiuniprim_prop gg on g.cod=gg.gestiune where gg.gestiune IS NULL and ISNULL(g.primitoare,0)=1
		set @gestprop_err = 'Nu aveti drepturi pe aceasta gestiune ca primitoare(' + left(@gestprop_err,LEN(@gestprop_err)-1) + ')!'
		raiserror(@gestprop_err,16,1)
	end

	/** Gestiuni declarate invalide */
	select g.* into #gestiuniInv from #gestiuni g inner join gestiuni ge on g.cod = ge.Cod_gestiune
	where g.Data between ge.detalii.value('(/row/@data_invalid_jos)[1]', 'datetime')
		and ge.detalii.value('(/row/@data_invalid_sus)[1]', 'datetime')

	if (select count(*) from #gestiuniInv) > 0
	begin
		declare @mesajInvalidare varchar(max), @nr int
		set @mesajInvalidare = ''
		select @nr = count(*) from #gestiuniInv
		select @mesajInvalidare = @mesajInvalidare + RTRIM(Cod) + ', ' from #gestiuniInv
		set @mesajInvalidare = left(@mesajInvalidare, len(@mesajInvalidare) - 1)

		set @mesajInvalidare = 'Nu se pot opera documente pe ' + (case when @nr > 1 then 'aceste gestiuni: ' else 'aceasta gestiune: ' end)
			+ @mesajInvalidare + (case when @nr > 1 then '. Declarate invalide!' else '. Declarata invalida!' end)
		raiserror(@mesajInvalidare, 16, 1)
	end

	if object_id('tempdb.dbo.#gestiuniInv') is not null drop table #gestiuniInv

end try
begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (validGestiune)'
	raiserror(@mesaj, 16,1)
end catch	
