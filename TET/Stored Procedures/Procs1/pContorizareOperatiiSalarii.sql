Create procedure pContorizareOperatiiSalarii @sesiune varchar(50), @parXML xml
as
begin try 
	/*	Apelam procedura specifica, pentru a putea modifica eventual durata. Sau pentru alte cazuri de validare. */
	if exists (select * from sysobjects where name ='pContorizareOperatiiSalariiSP')
		exec pContorizareOperatiiSalariiSP @sesiune=@sesiune, @parXML=@parXML OUTPUT

	/*	Se verifica daca ruleaza o operatie de calcul lichidare. Sa nu se poata rula alta pana ce nu se termina cea care ruleaza. */
	declare @utilizator varchar(20), @utilizatorCalcul varchar(20), @mesajCalcul varchar(1000), @calculInLucru int, 
		@datal datetime, @locm varchar(20), @tipOperatie varchar(2), @tipOperatieInCurs varchar(2), 
		@obiectSQL varchar(20), @durCalcul int, @testMesajInCurs varchar(100), @testMesaj varchar(100), @multiFirma int, @doarVerificare int
	
	SET @Utilizator = dbo.fIaUtilizator(@sesiune)

	set @durCalcul=dbo.iauParN('PS','DURCALCPS')
	if @durCalcul=0 
		set @durCalcul=2

	set @datal = @parXML.value('(/row/@datal)[1]', 'datetime')
	set @locm = ISNULL(@parXML.value('(/row/@locm)[1]', 'varchar(20)'), '')
	set @obiectSQL = ISNULL(@parXML.value('(/row/@obiectSQL)[1]', 'varchar(20)'), '')
	set @tipOperatie = ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '')
	set @doarVerificare = ISNULL(@parXML.value('(/row/@verificare)[1]', 'varchar(2)'), 0)

	if @durCalcul=0 
		set @durCalcul=2

	select top 1 @utilizatorCalcul=utilizator, @tipOperatieInCurs=tip 
	from contorOperatiiSalarii where (tip=@tipOperatie or @tipOperatie='CS' and tip='CL') and data_lunii=@datal and (@multiFirma=0 or Loc_de_munca=@locm) and DateDiff(mi,data,getdate())<=@durCalcul order by data desc
	set @testMesajInCurs=(case when @tipOperatieInCurs='CL' then 'calcul de lichidare' when @tipOperatieInCurs='CS' then 'calcul de salarii' else '' end)
	set @testMesaj=(case when @tipOperatie='CL' then 'calcul de lichidare' when @tipOperatie='CS' then 'calcul de salarii' else '' end)
	if @utilizatorCalcul is not null
	begin
		set @calculInLucru=1
		set @mesajCalcul='Ruleaza deja un '+rtrim(@testMesajInCurs)
			+' lansat de utilizatorul '+rtrim(upper(@utilizatorCalcul))
			+'! Reveniti pentru '+rtrim(@testMesaj)+' in '+rtrim(convert(char(3),@durCalcul))+' minute!'
		raiserror (@mesajCalcul,11,1)
	end
	
	if @doarVerificare=0
	begin
		set @utilizatorCalcul=(select utilizator from contorOperatiiSalarii where tip=@tipOperatie and data_lunii=@datal and (@multiFirma=0 or Loc_de_munca=@locm) and DateDiff(mi,data,getdate())>@durCalcul)
		if @utilizatorCalcul is not null
			delete from contorOperatiiSalarii where tip=@tipOperatie and data_lunii=@datal
		insert into contorOperatiiSalarii (utilizator, data_lunii, data, tip, loc_de_munca, obiectSql)
		select @utilizator, @datal, getdate(), @tipOperatie,  (case when @multiFirma=1 then @locm else '' end), @obiectSQL
	end
end try

Begin catch
	declare @eroare varchar(8000)
	/*	Daca da eroare, se goleste tabela.	*/
	if @calculInLucru is null
		delete from contorOperatiiSalarii where tip='CS' and data_lunii=@datal and (@multiFirma=0 or Loc_de_munca=@locm)

	set @eroare='Procedura pContorizareOperatiiSalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
