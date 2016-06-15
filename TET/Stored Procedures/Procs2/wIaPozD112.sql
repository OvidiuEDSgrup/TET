--***
Create procedure wIaPozD112 @sesiune varchar(50), @parXML xml
as  
Begin
	declare @userASiS varchar(10), @tip varchar(2), @an int, @cautare varchar(100), @data datetime
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	select @tip=xA.row.value('@tip', 'varchar(2)'), @data=xA.row.value('@datalunii', 'datetime'),
		@cautare=isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(50)'), '') 
	from @parXML.nodes('row') as xA(row) 

	select @tip as tip, 'CE' as subtip, e.cnpasig, isnull(rtrim(a.numeAsig)+' '+rtrim(a.prenAsig),'') as nume, 
		e.E3_1, e.E3_2, e.E3_3, e.E3_4, e.E3_5, e.E3_6, e.E3_7, e.E3_8, e.E3_9, e.E3_10, 
		e.E3_11, e.E3_12, e.E3_13, e.E3_14, e.E3_15, e.E3_16, e.idPozitie, '#000000' as culoare 
	from D112asiguratE3 e 
		left outer join D112asigurat a on a.Data=e.Data and a.cnpAsig=e.cnpAsig
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=e.Loc_de_munca
	where e.data between dbo.BOM(@data) and dbo.EOM(@data) and E3_4<>'P'
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null) 
	FOR XML raw
End
