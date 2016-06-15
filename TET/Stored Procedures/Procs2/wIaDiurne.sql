--***
CREATE procedure wIaDiurne @sesiune varchar(50), @parXML xml
as  
begin try
	declare @userASiS varchar(10), @LunaInch int, @AnulInch int, @DataInch datetime, @LunaBloc int, @AnulBloc int, @DataBloc datetime, 
	@tip varchar(2), @data datetime, @datajos datetime, @datasus datetime, @lmantet varchar(9), 
	@f_denlm varchar(50), @f_salariat varchar(50), @f_tara varchar(50), @f_valuta varchar(50), @mesaj varchar(1000)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))

	set @LunaBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNABLOC'), 1)
	set @AnulBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANULBLOC'), 1901)
	set @DataBloc=dbo.Eom(convert(datetime,str(@LunaBloc,2)+'/01/'+str(@AnulBloc,4)))

	select @tip=xA.row.value('@tip', 'char(2)'), @data=xA.row.value('@data','datetime'), 
		@datajos=dbo.Bom(isnull(xA.row.value('@datajos','datetime'),isnull(xA.row.value('@data','datetime'),'01/01/1901'))), 
		@datasus=dbo.Eom(isnull(xA.row.value('@datasus','datetime'),isnull(xA.row.value('@data','datetime'),'12/31/2999'))),
		@lmantet=xA.row.value('@lmantet','varchar(9)'), @f_denlm=xA.row.value('@f_denlm','varchar(50)'),
		@f_salariat=xA.row.value('@f_salariat','varchar(50)'), @f_tara=xA.row.value('@f_tara','varchar(50)'), 
		@f_valuta=xA.row.value('@f_valuta','varchar(50)')
	from @parXML.nodes('row') as xA(row)  

-->	calculez intr-o tabela temporara, diurna cuvenita pe perioada introdusa, pentru a o afisa in grid. 
-->	S-ar putea afisa in grid si diurna impozabila/neimpozabila/diurna zilnica.
	if OBJECT_ID('tempdb..#diurne') is not null drop table #diurne
	Create table #diurne (marca varchar(6))
	EXEC CreeazaDiezDiurne @numeTabela='#Diurne'
	insert into #diurne
	exec pCalculDiurne @dataJos=@dataJos, @dataSus=@dataSus, @marca=null, @lm=null, @genCorectii=0

	select @tip as tip, d.Loc_de_munca, rtrim(d.marca) as marca, rtrim(isnull(i.nume,p.Nume)) as densalariat, 
		convert(char(10),d.data_inceput,101) as datainceput, convert(char(10),d.data_sfarsit,101) as datasfarsit, convert(decimal(6,2),d.zile) as zile, 
		rtrim(d.tara) as tara, rtrim(t.denumire) as dentara, rtrim(d.valuta) as valuta, rtrim(d.valuta) as denvaluta, 
		rtrim(d.tip_diurna) as tipdiurna, rtrim((case when d.tip_diurna='B' then 'Brut' else 'Net' end)) as dentipdiurna, 
		convert(decimal(12,2),diurna) as diurna, convert(decimal(15,4),d.curs) as curs, idPozitie, 
		(case when d.Data_inceput<=@DataInch then '#808080' else '#000000' end) as culoare,
		(case when d.Data_inceput<=@DataInch or d.Data_inceput<=@DataBloc then 1 else 0 end) as _nemodificabil
	from diurne d
		left outer join istpers i on d.Marca=i.Marca and dbo.EOM(d.Data_inceput)=i.Data
		left outer join personal p on d.Marca=p.Marca 
		left outer join lm lm on lm.Cod=isnull(i.Loc_de_munca,p.loc_de_munca)
		left outer join tari t on t.Cod_tara=d.tara
		left outer join #diurne dc on dc.marca=d.marca and dc.data_inceput=d.data_inceput
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and i.Loc_de_munca=lu.cod
	where dbo.EOM(d.Data_inceput) between @datajos and @datasus 
		and (@f_denlm is null or lm.denumire like '%'+@f_denlm+'%')
		and (@lmantet is null or i.Loc_de_munca=@lmantet) 
		and (@f_salariat is null or i.Nume like '%'+@f_salariat+'%' or d.Marca like @f_salariat+'%')
		and (@f_tara is null or t.Denumire like '%'+@f_tara+'%' or d.Tara like @f_tara+'%')
		and (@f_valuta is null or d.Valuta like @f_valuta+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	for xml raw
end try

begin catch
	set @mesaj =ERROR_MESSAGE()+' (wIaDiurne)'
	raiserror(@mesaj,11,1)
end catch
