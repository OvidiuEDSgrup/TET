--***
create procedure wIaSoldTertSP @sesiune varchar(50), @parXML xml output
as 
begin try 
/*startsp
	if exists (select 1 from sysobjects where type='P' and name='wIaSoldTertSP')
	begin
		exec wIaSoldTertSP @sesiune=@sesiune, @parXML=@parXML output
		return 0
	end
--stopsp*/
	declare @mesajeroare varchar(500), @soldmaxim float, @tert varchar(50), @subunitate varchar(200),
			@totalIncasari float, @sold float, @blocSold bit, @blocScad bit, @zileScadBlocate int,
			@zileScadDepasite char(1)

	exec luare_date_par 'GE', 'SUBPRO', 0,0, @subunitate output
	exec luare_date_par 'GE', 'BLOCSOLD', @blocSold output, 0,''
	exec luare_date_par 'GE', 'BLOCSCAD', @blocScad output, @zileScadBlocate output,''
	
	if @blocScad=0 and @blocSold=0
	begin
		set @parXML=null
		return
	end
	
	select	@tert=ISNULL(@parXML.value('(/row/@tert)[1]','varchar(100)'), '')
	
	select @soldmaxim=0, @sold=0, @zileScadDepasite='0'
	
	select @sold=@sold + f.sold, 
		@zileScadDepasite = case @zileScadDepasite 
			when '0' then (case when DATEADD(DAY, @zileScadBlocate, f.Data_scadentei)<GETDATE() then '1' else '0' end)
			else @zileScadDepasite end
	from facturi f
	where f.subunitate=@subunitate and f.tip=0x46 and f.tert=@Tert and f.Sold>=0.01
/*startsp
	and sold>0.001
--stopsp*/

--/*startsp
	select @sold=@sold + e.sold
		--@zileScadDepasite = (case when DATEADD(DAY, @zileScadBlocate, f.Data_scadentei)<GETDATE() then '1' else '0' end)
	from efecte e
	where e.subunitate=@subunitate and e.tip='I' and e.tert=@Tert 
	
	declare @gestiune varchar(9)='700'
	select @sold=@sold + s.Stoc*convert(decimal(15,2),s.Pret_cu_amanuntul)
		--@zileScadDepasite = (case when DATEADD(DAY, @zileScadBlocate, f.Data_scadentei)<GETDATE() then '1' else '0' end)
	from stocuri s 
		inner join nomencl n on s.cod=n.cod
		left join pozcon pc on pc.Subunitate=s.Subunitate and pc.Tip='BK' and pc.Contract=s.Contract and pc.Cod=s.Cod
	where 
		s.subunitate=@subunitate 
		and s.Cod_gestiune=@gestiune
		and (s.Comanda=@tert or pc.Tert=@tert)
		and s.stoc>=0.001
--stopsp*/
	
	if @blocSold=1
	begin	
		select @soldmaxim= t.Sold_maxim_ca_beneficiar
			from terti t where t.Tert=@tert and t.Subunitate=@subunitate
		if @soldmaxim=0
			set @soldmaxim=999999999.00 -- Ghita, 28.06.2012: daca nu se completeaza se considera neblocat
		
		if @parXML.value('(/row/@sold)[1]','varchar(50)') is null
			set @parXML.modify ('insert attribute sold {sql:variable("@sold")} into (/row)[1]')
		else
			set @parXML.modify('replace value of (/row/@sold)[1] with sql:variable("@sold")')
		
		if @parXML.value('(/row/@soldmaxim)[1]','varchar(50)') is null
			set @parXML.modify ('insert attribute soldmaxim {sql:variable("@soldmaxim")} into (/row)[1]')
		else
			set @parXML.modify('replace value of (/row/@soldmaxim)[1] with sql:variable("@soldmaxim")')
	end
	
	if @blocScad=1 and @zileScadDepasite='1'
		if @parXML.value('(/row/@zilescadentadepasite)[1]','varchar(50)') is null
			set @parXML.modify ('insert attribute zilescadentadepasite {sql:variable("@zileScadDepasite")} into (/row)[1]')
		else
			set @parXML.modify('replace value of (/row/@zilescadentadepasite)[1] with sql:variable("@zileScadDepasite")')
	
end try
begin catch
	set @mesajeroare=ERROR_MESSAGE()+'(wIaSoldTertSP)'
	raiserror(@mesajeroare,11,1)
end catch

