create procedure validNomencl  
as
begin try
	/*
		Se valideaza folosind tabela #nomencl (cod varchar(20), Data datetime)
			- existenta in catalog si "blank"
			- coduri declarate invalide pe o anumita perioada
			
	*/

	if exists(select 1 from #nomencl where cod='' )
	begin
		raiserror('Cod nomenclator necompletat!',16,1)
	end

	if exists(select 1 from #nomencl n left join nomencl nn on n.cod=nn.cod where nn.cod is null)
	begin
		declare
			@nomencl_err varchar(MAX)
		set @nomencl_err = ''
		select @nomencl_err = @nomencl_err + RTRIM(n.cod) + ',' from #nomencl n left join nomencl nn on n.cod=nn.cod where nn.cod is null
		set @nomencl_err = 'Cod nomenclator inexistent in catalog (' + left(@nomencl_err,LEN(@nomencl_err)-1) + ')!'
		raiserror(@nomencl_err,16,1)
	end

	/** Coduri declarate invalide */
	select n.* into #nomInv from #nomencl n inner join nomencl nn on n.cod = nn.cod
	where n.Data between nn.detalii.value('(/row/@data_invalid_jos)[1]', 'datetime')
		and nn.detalii.value('(/row/@data_invalid_sus)[1]', 'datetime')

	if (select count(*) from #nomInv) > 0
	begin
		declare @mesajInvalidare varchar(max) , @nr int
		select @mesajInvalidare ='' 
		select @nr = count(*) from #nomInv
		select @mesajInvalidare = @mesajInvalidare + RTRIM(Cod) + ', ' from #nomInv
		set @mesajInvalidare = left(@mesajInvalidare, len(@mesajInvalidare) - 1)

		set @mesajInvalidare = 'Nu se pot opera documente cu ' + (case when @nr > 1 then 'aceste coduri: ' else 'acest cod: ' end)
			+ @mesajInvalidare + (case when @nr > 1 then '. Declarate invalide!' else '. Declarat invalid!' end)
		raiserror(@mesajInvalidare, 16, 1)
	end

	if object_id('tempdb.dbo.#nomInv') is not null drop table #nomInv

end try
begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (validNomencl)'
	raiserror(@mesaj, 16,1)
end catch
