--***
/**	procedura ce returneaza date pt. declaratia 205 */
Create procedure extragDetaliiIstpers @parXML xml
as  
/*
	@grupare=1	-> grupare pe tipuri de venit
*/
Begin try
	set transaction isolation level read uncommitted
	declare @datajos datetime, @datasus datetime, @utilizator varchar(20), @lista_lm int
	set @datajos = @parXML.value('(/row/@datajos)[1]', 'datetime')
	set @datasus = @parXML.value('(/row/@datasus)[1]', 'datetime')

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	insert into #istpersdetalii 
	select data, marca, detalii.value('(/row/@tipsalar205)[1]','varchar(1)') as tipsalar 
	from istpers i
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
	where i.data between @dataJos and @dataSus 
		and (@lista_lm=0 or lu.cod is not null)
	
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura extragDetaliiIstpers (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec rapDeclaratia205 '01/01/2012', '12/31/2012', 0, '07', 0, '','', '', null, 0, '', 1, null, null, '1880107203671'
*/
