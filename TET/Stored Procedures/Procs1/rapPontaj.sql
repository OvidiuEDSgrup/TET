Create procedure rapPontaj
	(@dataJos datetime, @dataSus datetime, @locm varchar(9)=null, @marca varchar(6)=null, @comanda varchar(20)=null, @strict int=0)
as
begin try
	set transaction isolation level read uncommitted
	
	declare @utilizator varchar(20), @dreptConducere int, @areDreptCond int, @lista_drept char(1) 
	set @utilizator = dbo.fIaUtilizator('')
	set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	IF @utilizator IS NULL
		RETURN -1

--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @lista_drept='T'
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0
			set @lista_drept='S'
	end 

	select 
	s.marca, s.nume, s.cod_functie, f.denumire as den_functie, s.salar_de_incadrare, s.salar_de_baza	--antet salariat
	, isnull(r.loc_de_munca,p.loc_de_munca) as loc_de_munca, lm.denumire as den_lm, isnull(r.comanda,'') as comanda, c.descriere as den_comanda	--antet comenzi
	/*,Ore_lucrate*/, 
	p.data, Ore_regie, Ore_acord, Ore_suplimentare_1, Ore_suplimentare_2, Ore_suplimentare_3, Ore_suplimentare_4, Ore_spor_100, Ore_de_noapte, Ore_intrerupere_tehnologica, 
	Ore_concediu_de_odihna, Ore_concediu_medical, Ore_invoiri, Ore_nemotivate, Ore_obligatii_cetatenesti, Ore_concediu_fara_salar, Ore_donare_sange, Coeficient_acord, Coeficient_de_timp, 
	Ore_realizate_acord, Ore_sistematic_peste_program, Ore__cond_1, Ore__cond_2, Ore__cond_3, Ore__cond_4, Ore__cond_5, Ore__cond_6, p.Grupa_de_munca, Ore	--pontaj
	from 
	pontaj p
		left join realcom r on p.marca=r.marca and p.loc_de_munca=r.loc_de_munca and p.data=r.data and 'PS'+rtrim(p.numar_curent)=isnull(r.numar_document,'')
		inner join personal s on s.marca=p.marca
		inner join istPers i on i.marca=p.marca and i.Data=dbo.EOM(p.Data)
		left join functii f on f.cod_functie=isnull(i.Cod_functie,s.cod_functie)
		left join lm on lm.cod=isnull(r.loc_de_munca,p.loc_de_munca)
		left join comenzi c on c.comanda=r.comanda and '1'=c.subunitate
	where p.data between @datajos and @datasus
		and (@locm is null or p.loc_de_munca like rtrim(@locm)+(case when @strict=1 then '' else '%' end))
		and (@marca is null or p.marca=@marca)
		and (@comanda is null or r.comanda like @comanda)
		and (@dreptConducere=0 or (@dreptConducere=1 and @areDreptCond=1 and (@lista_drept='T' or @lista_drept='C' and s.pensie_suplimentara=1 or @lista_drept='S' and s.pensie_suplimentara<>1)) 
		or (@dreptConducere=1 and @areDreptCond=0 and @lista_drept='S' and s.pensie_suplimentara<>1))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=p.Loc_de_munca))
	order by f.cod_functie,r.marca,r.data

end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapPontaj (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec rapPontaj '03/01/2012', '03/31/2012', null, '1', null, 14, 0, 0
*/
