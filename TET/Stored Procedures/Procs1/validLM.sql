create procedure validLM  
as
begin try
	if exists (select 1 from sys.objects where name='validLMSP' and type='P')  
	begin
		exec validLMSP 
		return
	end

	/*
		Se valideaza folosind tabela #lm (lm,data, utilizator)
			- verificare validare stricta in functie de parametru
			- existenta in catalog
			- drepturi pe utilizator/loc de munca
			- "expirare"
	*/
	declare 
		@validlmstrict int
	set @validlmstrict=0 --Valoarea implicita

	select top 1 @validlmstrict=val_numerica from par where tip_parametru='GE' and parametru = 'CENTPROF'

	if @validlmstrict=1 and exists(select 1 from #lm where cod='')
		raiserror('Loc de munca necompletat!',16,1)
			
	if exists(select 1 from #lm l1 left outer join lm l2 on l1.cod=l2.cod where l1.cod<>'' and l2.cod is null)
	begin
		declare @lmerr varchar(8000),@errMsg varchar(8000)
		set @lmerr=''
		select @lmerr=@lmerr+l1.cod+',' from #lm l1 
			left outer join lm l2 on l1.cod=l2.cod where l1.cod<>'' and l2.cod is null
		set @lmerr=left(@lmerr,len(@lmerr)-1)
		set @errMsg='Loc de munca inexistent in catalog('+@lmerr+')!'
		raiserror(@errMsg,16,1)
	end

	/*	Am mutat aici partea de bugetari pentru a se valida existenta locului de munca.*/
	if left(cast(CONTEXT_INFO() as varchar),17)='specificebugetari'
		return

	if (select count(*) from lmfiltrare l1 inner join #lm l2 on l1.utilizator=l2.utilizator)>0 
		and exists(select 1 from #lm l1 left join lmfiltrare l2 on l1.utilizator=l2.utilizator and l1.cod=l2.cod where l2.cod is null)
		raiserror('Nu puteti opera pe acest loc de munca!',16,1)

	if exists (select 1 from #lm l JOIN validcat vl on l.cod=vl.cod and vl.tip='LM' where l.data between vl.data_jos and vl.data_sus )
		or exists (select 1 from #lm l JOIN lm on l.cod = lm.Cod where l.data between lm.detalii.value('(/row/@data_invalid_jos)[1]', 'datetime')
		and lm.detalii.value('(/row/@data_invalid_sus)[1]', 'datetime'))
		RAISERROR ('Violare integritate date. Nu se poate opera pe acest loc de munca (declarat invalid).', 16, 1)

	-- validare suplimentara: 
	if exists (select 1 from sys.objects where name='validLMSP1' and type='P')  
		exec validLMSP1 
end try
begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (validLM)'
	raiserror(@mesaj, 16,1)
end catch

