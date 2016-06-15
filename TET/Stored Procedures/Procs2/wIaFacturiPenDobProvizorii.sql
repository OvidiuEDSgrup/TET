--***
create procedure wIaFacturiPenDobProvizorii @sesiune varchar(30), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaFacturiPenDobProvizoriiSP')
begin 
	declare @returnValue int 
	exec @returnValue = wIaFacturiPenDobProvizoriiSP @sesiune, @parXML output
	return @returnValue
end

Declare @tip varchar(2),@datajos datetime,@mesaj varchar(200),@datasus datetime,@filtruTert varchar(13),
	@utilizator char(20),@tert varchar(13),@fstare_pentert varchar(13),@filtruTip_pen varchar(20),@filtruLm varchar(50)
begin try		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	select
		@datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
		@datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(3)'),''),
		@tert = isnull(@parXML.value('(/row/@tert)[1]','varchar(13)'),''),
		@filtruTert = isnull(@parXML.value('(/row/@filtrutert)[1]','varchar(13)'),''),
		@filtruLm = isnull(@parXML.value('(/row/@filtruLm)[1]','varchar(50)'),''),
		@filtruTip_pen = isnull(@parXML.value('(/row/@ftip_pen)[1]','varchar(20)'),''),
		@fstare_pentert = isnull(@parXML.value('(/row/@fstare_pentert)[1]','varchar(13)'),'')
				
	declare @lista_lm int
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	select Top 100 rtrim(p.Tert) as tert,convert(decimal(17,3),SUM(p.Sold_penalizare))as sold_penalizareT,
		convert(decimal(17,1),SUM(p.Zile_penalizare))as zile_penalizareT,
		convert(decimal(17,3),SUM(Suma_penalizare)) as suma_penalizareT,rtrim(max(t.Denumire)) as dentert,
		(case when exists(select 1 from penalizarifact where tert=p.Tert and Stare<>'F') then '#000000' 
		else '#A4A4A4'  end)  as culoare,@datajos as datajos,@datasus as datasus,@filtruLm as filtruLm,
		-- date necesare forular anexa dobanzi/penalitati
		'AS' as tip, @datajos as data, convert(char(10),@datasus,101) as numar
	from penalizarifact p 
		left outer join terti t on t.Tert=p.Tert
		left join lm on lm.Cod=p.loc_de_munca
		left join lmfiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
	where p.Data_penalizare between @datajos and @datasus
		and (@lista_lm=0 OR p.loc_de_munca IS null or p.loc_de_munca is not null 
			and lu.cod is not null)
		and (p.Tert=@tert or isnull(@tert,'')='')
		and (p.Tert like @filtruTert+'%' or t.Denumire like '%'+@filtruTert+'%' and ISNULL(@filtruTert,'')<>'')
		and (p.tip_penalizare =left(@filtruTip_pen,1) or ISNULL(@filtruTip_pen,'')='')
		and (p.loc_de_munca like @filtruLm+'%' or lm.Denumire like '%'+@filtruLm+'%' and ISNULL(@filtruLm,'')<>'')
		and (not exists(select 1 from penalizarifact where tert=p.Tert and Stare=case when left(@fstare_pentert,1)='F' then 'P' else 'F'end)or ISNULL(@fstare_pentert,'')='' )
		
	group by p.Tert
	order by max(t.Denumire)
	for xml raw
end try
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch

/*
select * from penalizarifact
*/
