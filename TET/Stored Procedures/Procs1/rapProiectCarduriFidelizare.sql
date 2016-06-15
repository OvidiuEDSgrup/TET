--***
create procedure rapProiectCarduriFidelizare @datajos datetime=null,@datasus datetime=null,@card varchar(100)=null,@gestiune varchar(9)=null
as
begin

-- exec rapProiectCarduriFidelizare '1901-01-01','2999-01-01','004388'

	set transaction isolation level read uncommitted
	declare @eroare varchar(2000)
	if @datajos is null
		set @datajos=isnull(@datajos,convert(varchar(20),dbo.eom('01/01/1900'),102))
	if @datasus is null
		set @datasus=isnull(@datasus,convert(varchar(20),dbo.eom(getdate()),102))

	begin try
		if object_id('tempdb..#degrupat') is not null drop table #degrupat

		select cf.Nume_posesor_card, pp.uid_card,cf.Telefon_posesor_card,cf.Email_posesor_card,
			(case when a.Data_bon>@datajos then (case when tip='D' then 1 else -1 end)*pp.puncte else 0 end) sold_initial,
			(case when tip='D' then pp.puncte else 0 end) as debit,
			(case when tip='C' then pp.puncte else 0 end) as credit,
			a.data_bon
		into #degrupat
		from pvpuncte pp
			join CarduriFidelizare cf on pp.UID_Card=cf.UID
			join antetBonuri a on pp.idantetbon=a.idAntetBon
		where a.Data_bon<=@datasus and (@card is null or pp.uid_card=@card) and (@gestiune is null or a.gestiune=@gestiune)

		create clustered index ind on #degrupat(data_bon asc)
		declare @soldi decimal(15,3)
		set @soldi=0
		
		update d set sold_initial=@soldi-(debit-credit),
					@soldi=@soldi+debit-credit
		from #degrupat d
		
		
--select * from #degrupat
--return

/*		select Nume_posesor_card, max(Telefon_posesor_card) telefon, max(Email_posesor_card) email,
			'' uid_card, sum(sold_initial+debit-credit) sold_initial, 0 debit, 0 credit, dateadd(d,-1,@datajos) data_bon
		from #degrupat
		where data_bon<@datajos
		group by Nume_posesor_card
			union all*/
		select Nume_posesor_card, Telefon_posesor_card, Email_posesor_card, 
			uid_card, sold_initial, debit, credit, data_bon
		from #degrupat
		where data_bon>=@datajos
		order by nume_posesor_card, data_bon

		if object_id('tempdb..#degrupat') is not null drop table #degrupat
		--group by pp.UID_card, cf.Nume_posesor_card, a.Data_bon
	end try
	begin catch
		select @eroare=error_message()+' (rapProiectCarduriFidelizare)'
		raiserror (@eroare,16,1)
	end catch
end
