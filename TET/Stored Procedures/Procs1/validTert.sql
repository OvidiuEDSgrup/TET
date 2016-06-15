create procedure validTert  
as
begin try
	/*
		Se valideaza folosind tabela #terti (cod varchar(20))
			- existenta in catalog si "blank"
			
	*/

	if exists(select 1 from #terti where cod='')
	begin
		raiserror('Tert necompletat!',16,1)
	end

	if exists(select 1 from #terti t left join terti tt on t.cod=tt.tert where tt.tert is null)
	begin
		declare
			@tert_err varchar(MAX)
		set @tert_err = ''
		select @tert_err = @tert_err + RTRIM(t.cod) + ',' from #terti t left join terti tt on t.cod=tt.tert where tt.tert is null
		set @tert_err = 'Tert inexistent in catalog (' + left(@tert_err,LEN(@tert_err)-1) + ')!'		-- Sterg ultima virgula din @tert_err
		raiserror(@tert_err,16,1)
	end

end try
begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (validTert)'
	raiserror(@mesaj, 16,1)
end catch
