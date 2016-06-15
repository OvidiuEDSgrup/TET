--***
Create procedure rapDiurne
	@dataJos datetime
	,@dataSus datetime
	,@marca char(9)=null	-->	pentru filtrare marca
	,@lm char(9)=null		-->	pentru filtrare loc de munca like
	,@ordonare int=0		-->	0=grupare pe salariati, 1=grupare pe locuri de munca
as  
Begin try
	declare @utilizator varchar(20), @lista_lm int

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	if OBJECT_ID('tempdb..#diurne') is not null drop table #diurne

	Create table #diurne (marca varchar(6))
	EXEC CreeazaDiezDiurne @numeTabela='#Diurne'

	insert into #diurne
	exec pCalculDiurne @dataJos, @dataSus, @marca, @lm

	select row_number() over (order by (case when @ordonare='1' then d.loc_de_munca else '' end),p.nume,d.data_inceput) as id, 
		rtrim(d.marca) as marca, rtrim(p.nume) as nume, rtrim(d.loc_de_munca) as lm, rtrim(lm.Denumire) as den_lm, rtrim(d.cod_functie) as cod_functie, rtrim(f.Denumire) as den_functie, 
		convert(varchar(10),d.data_inceput,103)+' - '+convert(varchar(10),d.data_sfarsit,103) as perioada, convert(decimal(4,1),d.zile) as zile, d.tara, 
		rtrim(t.denumire) as den_tara, d.valuta, d.tip_diurna, 
		d.curs, d.diurna_zi, d.diurna_neimpozabila_zi, d.diurna, d.diurna_neimpozabila, d.diurna_impozabila, d.diurna_lei, d.diurna_neimpozabila_lei, d.diurna_impozabila_lei, idDiurna
	from #diurne d 
		left outer join personal p on p.marca=d.marca
		left outer join istPers ip on ip.marca=d.marca and ip.data=dbo.EOM(d.data_inceput)
		left outer join functii f on f.cod_functie=d.cod_functie
		left outer join lm on lm.cod=d.loc_de_munca
		left outer join tari t on t.cod_tara=d.tara
	order by (case when @ordonare='1' then d.loc_de_munca else '' end),p.nume,d.data_inceput
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapDiurne (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch


/*
	exec pCalculDiurne '01/01/2014', '01/31/2014', null, null
*/
