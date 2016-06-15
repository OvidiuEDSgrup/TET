/*
	exec rapFormFluturas @sesiune=null, @parXML='<row datasus="10/31/2014" marca="1056" />'	
*/
/* procedura pentru formularul web de vizualizare fluturasi */
Create procedure [dbo].[rapFormFluturas] @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@sub varchar(9), @utilizator varchar(20), @lista_lm int, @CodBenGarMat varchar(100), 
		@datajos datetime, @datasus datetime, @locm varchar(9), @marca varchar(6), @Luna varchar(20)
		
	select @Sub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),''),
		@CodBenGarMat=isnull((select max(val_alfanumerica) from par where tip_parametru='PS' and parametru='CODBGMAT'),'')

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	select @datasus=@parXML.value('(/row/@datasus)[1]','datetime'),
		@locm=isnull(@parXML.value('(/row/@locm)[1]','varchar(9)'),''),
		@marca=isnull(@parXML.value('(/row/@marca)[1]','varchar(6)'),'')
	set @datajos=dbo.bom(@datasus)
	set @Luna=dbo.fDenumireLuna(@datasus)

	delete from avnefac where terminal=@utilizator
	insert into avnefac(Terminal,Subunitate,Tip,Numar,Cod_gestiune,Data,Cod_tert,Factura,Contractul, 
		Data_facturii,Loc_munca,Comanda,Gestiune_primitoare,Valuta,Curs,Valoare,Valoare_valuta,Tva_11,Tva_22,Cont_beneficiar,Discount) 
	values (@utilizator,'1','FS',@marca,'',@dataSus,'','',@utilizator,@dataJos,@locm,'','Nume','',0,0,0,0,0,'',0) 

	exec ptFluturasi @cTerm=@utilizator, @sesiune=@sesiune

	if object_id('tempdb..#pontajMarca') is not null drop table #pontajMarca
	if object_id('tempdb..#istpers') is not null drop table #istpers
	if object_id('tempdb..#resal_garantii') is not null drop table #resal_garantii
	if OBJECT_ID('tempdb..#zileCOcuv') is not null drop table #zileCOcuv

-->	pun datele in tabela temporara pentru viteza mai buna. In #istpers se fac toate filtrarile, si apoi se face referire la ea.
	select i.* into #istpers
	from istpers i
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
	where i.data between @dataJos and @dataSus
		and (@lista_lm=0 or lu.cod is not null)
		and (@marca='' or i.marca=@marca)
		and (@locm='' or i.loc_de_munca like rtrim(@locm)+'%')

-->	In #pontajMarca se pun zilele de CO efectuate in anul curent si zilele de CM efectuate in ultimele 12 luni.
	select j.marca, round(sum((case when year(j.data)=year(@datasus) then ore_concediu_de_odihna/regim_de_lucru else 0 end)),0) as zile_co,
		round(sum(ore_concediu_medical/regim_de_lucru),2) as zile_cm
	into #pontajMarca
	from pontaj j 
		inner join istpers i on i.Marca=j.marca
	where j.data between dbo.eom(dateadd(month,-11,@datasus)) and @datasus
	group by j.marca

	select r.marca, round(sum(retinut_la_lichidare),2) as GarantiiMateriale
	into #resal_garantii
	from resal r 
		inner join istpers i on i.Marca=r.marca
	where r.Data = @datasus and r.cod_beneficiar=@CodBenGarMat
	group by r.marca

	create table #zileCOcuv (marca varchar(6), zile int)
	exec pZileCOcuvenite @marca=@marca, @data=@dataSus, @Calcul_pana_la_luna_curenta=0
	
	select
		rtrim(@Luna) as LUNA, convert(varchar(4), year(max(avn.data))) as ANUL,
		(select rtrim(Marca_i) from Flutur b where f.HostID = b.HostID and f.marca_i = b.marca_i and b.nr_linie = 1 and b.marca_p = 'V') as OB001,
		(select rtrim(Text_i) from Flutur b where f.HostID = b.HostID and f.marca_i = b.marca_i and b.nr_linie = 1 and b.marca_p = 'V') as OB002,
		rtrim(max(fct.denumire)) as OB003, rtrim(max(lm.denumire)) as OB0031,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='V'),'') as OB004,
-->	De aici incepe componenta brutului.
		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='V'),'') as OB005,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='V'),'') as OB005a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='V'),'') as OB005b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='V'),'') as OB006,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='V'),'') as OB006a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='V'),'') as OB006b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='V'),'') as OB007,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='V'),'') as OB007a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='V'),'') as OB007b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='V'),'') as OB008,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='V'),'') as OB008a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='V'),'') as OB008b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='V'),'') as OB009,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='V'),'') as OB009a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='V'),'') as OB009b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='V'),'') as OB010,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='V'),'') as OB010a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='V'),'') as OB010b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='V'),'') as OB011,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='V'),'') as OB011a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='V'),'') as OB011b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='V'),'') as OB012,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='V'),'') as OB012a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='V'),'') as OB012b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='V'),'') as OB013,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='V'),'') as OB013a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='V'),'') as OB013b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=11 and b.marca_p='V'),'') as OB014,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=11 and b.marca_p='V'),'') as OB014a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=11 and b.marca_p='V'),'') as OB014b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=12 and b.marca_p='V'),'') as OB015,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=12 and b.marca_p='V'),'') as OB015a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=12 and b.marca_p='V'),'') as OB015b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=13 and b.marca_p='V'),'') as OB016,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=13 and b.marca_p='V'),'') as OB016a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=13 and b.marca_p='V'),'') as OB016b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=14 and b.marca_p='V'),'') as OB017,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=14 and b.marca_p='V'),'') as OB017a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=14 and b.marca_p='V'),'') as OB017b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=15 and b.marca_p='V'),'') as OB018,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=15 and b.marca_p='V'),'') as OB018a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=15 and b.marca_p='V'),'') as OB018b,

-->	Pana aici sunt veniturile si de aici incep contributiile/venitul net.
		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='C'),'') as C01,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='C'),'') as C01a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='C'),'') as C01b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='C'),'') as C02,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='C'),'') as C02a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='C'),'') as C02b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='C'),'') as C03,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='C'),'') as C03a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='C'),'') as C03b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='C'),'') as C04,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='C'),'') as C04a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='C'),'') as C04b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='C'),'') as C05,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='C'),'') as C05a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='C'),'') as C05b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='C'),'') as C06,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='C'),'') as C06a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='C'),'') as C06b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='C'),'') as C07,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='C'),'') as C07a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='C'),'') as C07b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='C'),'') as C08,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='C'),'') as C08a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='C'),'') as C08b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='C'),'') as C09,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='C'),'') as C09a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='C'),'') as C09b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='C'),'') as C10,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='C'),'') as C10a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='C'),'') as C10b,
		
-->	De aici incep retinerile
		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='R'),'') as R01,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='R'),'') as R01a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='R'),'') as R01b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='R'),'') as R02,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='R'),'') as R02a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='R'),'') as R02b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='R'),'') as R03,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='R'),'') as R03a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='R'),'') as R03b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='R'),'') as R04,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='R'),'') as R04a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='R'),'') as R04b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='R'),'') as R05,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='R'),'') as R05a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='R'),'') as R05b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='R'),'') as R06,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='R'),'') as R06a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='R'),'') as R06b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='R'),'') as R07,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='R'),'') as R07a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='R'),'') as R07b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='R'),'') as R08,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='R'),'') as R08a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='R'),'') as R08b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='R'),'') as R09,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='R'),'') as R09a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='R'),'') as R09b,

		isnull((select rtrim(Text_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='R'),'') as R10,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='R'),'') as R10a,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='R'),'') as R10b,

-->	Date finale (Venit brut, Rest de plata, Tichete, zile CO, etc)
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.text_i='VENIT TOTAL'),0) as VT,
		isnull((select count(1) from persintr b where f.marca_i = b.marca and b.data = max(avn.data) and b.Coef_ded <> 0), 0) as [PI],
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.text_i='REST DE PLATA'),0) as RP,
		isnull((select rtrim(Ore_procent_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.text_i='Tichete'),0) as NRTICH,
		isnull((select rtrim(Valoare_i) from Flutur b where f.HostID=b.HostID and f.marca_i=b.marca_i and b.text_i='Tichete'),0) as VALTICH,
		max(p.Zile_concediu_de_odihna_an) as ZILECO,
		max(zccuv.zile) as ZILECOCUV,
		convert(char(3),isnull(max(ia.coef_invalid),0)) as ZILECOANANT,
		convert(char(6),isnull(max(po.zile_co),0)) as ZILECOEF,
		convert(char(6),isnull(max(ia.coef_invalid),0)+max(zccuv.zile)-isnull(max(po.zile_co),0)) as SOLDZILECO,
		convert(char(6),isnull(max(po.zile_cm),0)) as ZILECM,
		max(convert(char(2),convert(int,right(convert(char(4),year(p.vechime_totala)),2))))+' ani '+max(convert(char(2),month(p.vechime_totala)))+' luni' as VECHT,
		max(convert(char(2),convert(int,right(convert(char(4),year(avn.data-p.data_angajarii_in_unitate)),2))))+' ani '+max(convert(char(2),month(avn.data-p.data_angajarii_in_unitate)))+' luni' as VECHU,
		convert(char(6),isnull(max(rg.GarantiiMateriale),0)) as GM
	from Flutur f
		left join personal p on p.Marca = f.Marca_i
		left join #pontajMarca po on po.Marca = f.Marca_i
		left join #resal_garantii rg on rg.Marca = f.Marca_i
		inner join avnefac avn on avn.Subunitate = @Sub and avn.Tip = 'FS' and avn.Contractul = f.HostID
		left join istPers i on i.Marca = f.Marca_i and i.Data = avn.Data
		left join istPers ia on ia.Marca = f.Marca_i and year(ia.data) = year(avn.data)-1 and month(ia.data)=12
		left join functii fct on fct.Cod_functie = i.Cod_functie
		left join net on net.Marca = f.Marca_i and net.Data = avn.Data
		left join lm on lm.Cod = net.Loc_de_munca
		left join #zileCOcuv zccuv on zccuv.Marca = f.Marca_i
	group by f.Hostid, f.Marca_i
	
	delete from avnefac where terminal=@utilizator
end try

begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
