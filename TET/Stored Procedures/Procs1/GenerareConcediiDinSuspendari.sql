--***
/**	procedura generare concedii (CFS, Nemotivate, ingrijire copil pana la 2 ani) pornind de la datele inregistrate ca suspendari in macheta de salariati */
Create procedure GenerareConcediiDinSuspendari
	@dataJos datetime, @dataSus datetime, @pMarca char(6)=null, @pLocm char(9)=null, @stergere int=0, @generare int=1
As
/*
	exec GenerareConcediiDinSuspendari '03/01/2013', '03/31/2013', null, null, 1, 1
*/
Begin try
	declare @userASiS char(10), @Data_operarii datetime, @Ora_operarii char(6), @formaJuridica varchar(100), @Grup7 int, @OreLuna float

	set @userASiS=dbo.fIaUtilizator(null)

	exec luare_date_par 'SP', 'GRUP7', @Grup7 output, 0, ''
	exec luare_date_par 'GE', 'FJURIDICA', 0, 0, @formaJuridica output
	set @OreLuna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')

	set @Data_operarii = convert(datetime, convert(char(10), getdate(), 104), 104) 
	set @Ora_operarii = replace(convert(char(8), getdate(), 114),':','')

--	pun intr-o tabela temporara suspendarile in vigoare in luna de lucru
	if object_id('tempdb..#suspendari') is not null drop table #suspendari
	select s.Data, s.Marca, 
		(case when s.Data_inceput<@datajos then @dataJos else s.Data_inceput end) as Data_inceput, 
		(case when (case when s.Data_incetare<>'01/01/1901' then s.Data_incetare else s.Data_sfarsit end)>@datasus 
			then @dataSus else (case when s.Data_incetare<>'01/01/1901' then DateADD(day,-1,s.Data_incetare) else s.Data_sfarsit end) end) as Data_sfarsit, 
		(case when p.Loc_ramas_vacant=1 then p.Data_plec else '01/01/1901' end) as Data_plec, 
		(case 
--	concediu de ingrijire copil pana la 2 ani
			when s.Temei_legal in ('Art51Alin1LiteraA','Art51Alin1LiteraB','Art51Alin1LiteraC') then '0-' 
--	concediu fara salar, nemotivate, cercetare disciplinara, Formare profesionala
			when s.Temei_legal='Art54' then '1' when s.Temei_legal='Art51Alin2' then '2' 
			when s.Temei_legal='Art52Alin1LiteraA' then '9' when s.Temei_legal='Art51Alin1LiteraD' then 'F'
			else '' end) as Tip_concediu
	into #suspendari
	from fRevisalSuspendari	(@dataJos, @dataSus, isnull(@pMarca,'')) s 
		left outer join personal p on p.Marca=s.Marca
	where (isnull(@pLocm,'')='' or p.Loc_de_munca like rtrim(@pLocm)+'%')

	update #suspendari set Data_sfarsit=(case when Data_plec>=Data_inceput and Data_plec<Data_sfarsit then DateADD(day,-1,Data_plec) else Data_sfarsit end) 

	delete cm
	from conmed cm
		left outer join personal p on p.Marca=cm.Marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
	where @stergere=1 and cm.Data=@dataSus and cm.Tip_diagnostic='0-' 
		and (isnull(@pMarca,'')='' or cm.marca=@pMarca) 
		and (isnull(@pLocm,'')='' or cm.Marca in (select Marca from personal where Loc_de_munca like rtrim(@pLocm)+'%'))
		and exists (select 1 from #suspendari s where s.Tip_concediu='0-' and s.Marca=cm.Marca)
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)

	insert into Conmed (Data, Marca, Tip_diagnostic, Data_inceput, Data_sfarsit, Zile_lucratoare, Zile_cu_reducere, Zile_luna_anterioara, Indemnizatia_zi, Procent_aplicat, 
		Indemnizatie_unitate, Indemnizatie_CAS, Baza_calcul, Zile_lucratoare_in_luna, Indemnizatii_calc_manual, Suma)
	Select @dataSus, s.Marca, '0-', s.Data_inceput, s.Data_sfarsit, dbo.Zile_lucratoare(s.Data_inceput, s.Data_sfarsit), 0, isnull(cm.Zile_luna_anterioara+cm.Zile_lucratoare,0), 0, 0, 0, 0, 0, @OreLuna/8, 0, 0
	from #suspendari s
		left outer join personal p on s.marca=p.marca 
		left outer join conmed cm on cm.Marca=s.Marca and cm.Data=DateADD(day,-1,@dataJos) and cm.Tip_diagnostic='0-' and cm.Data_sfarsit=DateADD(day,-1,@dataJos) 
	where @generare=1 and tip_concediu='0-'
		and not exists (select 1 from conmed b where b.data=@dataSus and b.Marca=s.Marca and b.Data_inceput=s.Data_inceput and b.Tip_diagnostic='0-')

	if @formaJuridica<>'' and @Grup7=0
	begin
		delete ca
		from conalte ca
			left outer join personal p on p.Marca=ca.Marca
			left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
		where @stergere=1 and ca.Data=@dataSus and ca.Data=dbo.EOM(Data) and Introd_manual=1 and not (Data_sfarsit>@dataSus)
			and (isnull(@pMarca,'')='' or ca.marca=@pMarca) 
			and (isnull(@pLocm,'')='' or ca.Marca in (select Marca from personal where Loc_de_munca like rtrim(@pLocm)+'%'))
			and exists (select 1 from #suspendari s where s.Tip_concediu in ('1','2','9','F') and s.Marca=ca.Marca)
			and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)

--	generez concedii\alte
		insert into conalte
		(Data, Marca, Tip_concediu, Data_inceput, Data_sfarsit, Zile, Introd_manual, Indemnizatie, Utilizator, Data_operarii, Ora_operarii)
		Select @dataSus, s.Marca, s.Tip_concediu, s.Data_inceput, s.Data_sfarsit, dbo.zile_lucratoare(s.Data_inceput, s.Data_sfarsit), 
			1, 0, @userASiS, @Data_operarii, @Ora_operarii
		from #suspendari s
			left outer join personal p on s.marca=p.marca 
		where @generare=1 and s.Tip_concediu in ('1','2','9','F')
			and not exists (select 1 from conalte b where b.data=@dataSus and b.Marca=s.Marca and b.Data_inceput=s.Data_inceput and b.Tip_concediu=s.Tip_concediu)
	end
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura GenerareConcediiDinSuspendari (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
