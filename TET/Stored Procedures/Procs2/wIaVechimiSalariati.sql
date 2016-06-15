--***
CREATE procedure wIaVechimiSalariati @sesiune varchar(50), @parXML xml
as  
begin try
	declare @tip varchar(2), @marca varchar(6), @mesajeroare varchar(500),@utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	if @utilizator is null
		return -1
	select @tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'),''),
		@marca=ISNULL(@parXML.value('(/row/@marca)[1]','varchar(6)'), '')

	select @tip as tip, 'VV' as subtip, 
		rtrim(v.Tip) as tipv,rtrim(v.Tip)+'-'+(case when v.Tip='T' then 'Vechime Totala' when v.Tip='I' then 'Vechime la intrare' 
			when v.Tip='M' then 'Vechime in meserie' else ''end) as dentipv,
		v.Numar_pozitie as numar_pozitie, convert(char(10),v.Data_inceput,101) as data_inceput, convert(char(10),v.Data_sfarsit,101) as data_sfarsit,
		rtrim(v.Unitate) as unitate, rtrim(v.Loc_de_munca) as loc_de_munca, rtrim(v.Functie) as functie,
		convert(int,v1.Loc_de_munca) as zilesuspend, convert(int,v1.Functie) as regim
	from vechimi v
		left outer join Vechimi v1 on v1.Marca=v.Marca and v1.Numar_pozitie=v.Numar_pozitie and v1.Tip=(case when v.tip='T' then '1' when v.tip='I' then '2' when v.tip='M' then '3' end)
	where v.marca=@marca and v.Tip in ('T','I','M')
	for xml raw
end try

begin catch
	set @mesajeroare=ERROR_MESSAGE()+' (wIaVechimiSalariati)'
	raiserror(@mesajeroare,11,1)
end catch
--select * from vechimi
