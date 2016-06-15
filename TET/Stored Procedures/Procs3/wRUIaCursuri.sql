--***
Create procedure wRUIaCursuri @sesiune varchar(50), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaCursuriSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaCursuriSP @sesiune, @parXML output
	return @returnValue
end

declare @filtruCurs varchar(30), @filtruDomeniu varchar(30), @filtruTipCurs varchar(30), @filtruTipCompententa varchar(30), @utilizator char(10), @lista_lm int, @mesaj varchar(200)
begin try
	set transaction isolation level READ UNCOMMITTED
	select
		@filtruCurs = isnull(@parXML.value('(/row/@f_curs)[1]', 'varchar(30)'), ''),
		@filtruDomeniu = isnull(@parXML.value('(/row/@f_domeniu)[1]', 'varchar(50)'), ''),
		@filtruTipCurs = isnull(@parXML.value('(/row/@f_tipcurs)[1]', 'varchar(50)'), ''),
		@filtruTipCompententa = isnull(@parXML.value('(/row/@f_tipcompetenta)[1]', 'varchar(50)'), '')
	select @filtruCurs = replace(@filtruCurs,' ','%'), 
		@filtruDomeniu = replace(@filtruDomeniu,' ','%')

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select @lista_lm=0
	select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @lista_lm end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('LOCMUNCA')
	
	if object_id('tempdb..#cursuri') is not null drop table #cursuri
	
	select top 100 a.ID_curs as id_curs, 
		(case when a.tip_competenta=1 then '1-TEHNICA' when a.tip_competenta=2 then '2-MANAGERIALA' when a.tip_competenta=3 then '3-GENERALA' end) as dentipcompetenta,
		(case when a.tip_curs=1 then '1-Instruire' when a.tip_curs=2 then '2-Perfectionare' when a.tip_curs=3 then '3-Specializare' 
		when a.tip_curs=4 then '4-Calificare' when a.tip_curs=5 then '5-Autorizare' when a.tip_curs=6 then '6-Atestare' end) as dentipcurs
	into #cursuri
	from RU_cursuri a 
		left outer join RU_domenii b on a.ID_domeniu=b.ID_domeniu
	where (@lista_lm=0 or a.ID_domeniu in (select Valoare from proprietati where tip='LM' and Cod_proprietate='DOMENIU' and Cod in (select Cod from LMFiltrare lu where lu.utilizator=@utilizator)))
		and	isnull(b.denumire,'') like '%' + @filtruDomeniu + '%'
		and	a.Denumire like '%' + @filtruCurs + '%'

	select top 100 a.ID_curs as id_curs, rtrim(a.Denumire) as dencurs, rtrim(a.Durata) as durata, rtrim(a.Periodicitate) as periodicitate, rtrim(a.Utilitate) as utilitate, 
		isnull(a.ID_domeniu,0) as id_domeniu, rtrim(isnull(b.denumire,'')) as dendomeniu, rtrim(a.Email) as email, 
		rtrim(a.tip_competenta) as tipcompetenta, 
		(case when a.tip_competenta=1 then '1-TEHNICA' when a.tip_competenta=2 then '2-MANAGERIALA' when a.tip_competenta=3 then '3-GENERALA' end) as dentipcompetenta,
		rtrim(a.tip_curs) as tipcurs, 
		(case when a.tip_curs=1 then '1-Instruire' when a.tip_curs=2 then '2-Perfectionare' when a.tip_curs=3 then '3-Specializare' 
		when a.tip_curs=4 then '4-Calificare' when a.tip_curs=5 then '5-Autorizare' when a.tip_curs=6 then '6-Atestare' end) as dentipcurs,
		'#000000' as culoare
	from RU_cursuri a 
		left outer join RU_domenii b on a.ID_domeniu=b.ID_domeniu
		inner join #cursuri c on a.ID_curs=c.ID_curs
	where (isnull(c.dentipcurs,'') like '%' + @filtruTipCurs + '%' or a.Tip_curs like @filtruTipCurs + '%')
		and (isnull(c.dentipcompetenta,'') like '%' + @filtruTipCompententa + '%' or a.Tip_competenta like @filtruTipCompententa + '%')
	for xml raw
	
	if object_id('tempdb..#cursuri') is not null drop table #cursuri
end try

begin catch
	set @mesaj = '(wRUIaCursuri) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
