--***
Create procedure rapSalariiZilieri
	@dataJos datetime, @dataSus datetime, @marca varchar(6)=null, @locm char(9)=null, @strict int=0, @centralizare char(1), @ordonare int, @alfabetic int
as
begin
	set transaction isolation level read uncommitted
	declare @userASiS char(10), @Sub varchar(9)
	-- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @userASiS=dbo.fIaUtilizator(null)
	set @Sub=dbo.iauParA('GE','SUBPRO')

	select (case when @Centralizare='M' then dbo.EOM(Data) else Data end) as Data, s.Marca as Marca, 
	max(z.Nume) as Nume, max(z.Cod_functie) as Cod_functie, max(f.Denumire) as DenFunctie, 
	max(s.loc_de_munca) as Loc_de_munca, max(lm.Denumire) as Denumire_LM, max(s.Comanda) as Comanda, max(isnull(c.Descriere,'')) as DenComanda, 
	sum(s.Ore_lucrate) as Ore_lucrate, max(s.Salar_orar) as Salar_orar, sum(s.Venit_total) as Venit_total, 
	sum(s.Impozit) as Impozit, sum(s.Rest_de_plata) as Rest_de_plata, 
	max(s.Nr_registru) as Nr_registru, max(s.Serie_registru) as Serie_registru, max(s.Pagina_registru) as Pagina_registru, max(s.Nr_curent_registru) as Nr_curent_registru, 
	max(s.Explicatii) as Explicatii, max(s.Data_platii) as Data_platii
	from SalariiZilieri s
		left outer join Zilieri z on s.marca = z.marca
		left outer join functii f on z.cod_functie = f.cod_functie
		left outer join lm on lm.Cod = z.Loc_de_munca
		left outer join comenzi c on c.Subunitate=@Sub and c.Comanda = s.Comanda
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=s.Loc_de_munca
	where s.data between @dataJos and @dataSus and (@marca is null or s.Marca=@marca)
		and (@locm is null or s.loc_de_munca like rtrim(@locm)+(case when @strict=1 then '' else '%' end))
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	Group By s.Marca, (case when @Centralizare='M' then dbo.EOM(Data) else Data end), (case when @Centralizare='M' then 0 else s.Nr_curent end)
	Order by (case when @Ordonare=1 then max(s.Loc_de_munca) else '' end), (case when @Alfabetic=0 then s.Marca else max(z.Nume) end), 
		(case when @Centralizare='M' then dbo.EOM(Data) else Data end)
	return
end

/*
	exec rapSalariiZilieri '12/01/2011', '12/31/2011', null, null, 0, '', '1', 1
*/
