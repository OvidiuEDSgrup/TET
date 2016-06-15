/**
	Procedura este folosita pentru a lista Adeverinte privind date din declaratia 205. 
**/
create procedure rapAdeverintaDeclaratia205 (@sesiune varchar(50), @marca varchar(6), @cnp varchar(13), @datajos datetime, @datasus datetime, @dataset char(2), @parXML xml='<row/>')
AS
/*
	exec rapAdeverintaDeclaratia205 '', '1', '01/01/2012', '12/31/2012', 'P', '<row />'
*/
begin try 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @denunit VARCHAR(100), @adrunit VARCHAR(100), @codfisc VARCHAR(100), @ordreg VARCHAR(100), @caen VARCHAR(100), @judet VARCHAR(100), @localit varchar(100), @contbanca VARCHAR(100), 
		@banca varchar(100), @dirgen varchar(100), @direc varchar(100), @sefpers varchar(100), @telefon varchar(100), @email varchar(100), 
		@compartiment varchar(100), @functierepr varchar(100), @numerepr varchar(100), @numec varchar(100), @functc varchar(100), 
		@tip varchar(2), @mesaj varchar(1000), @utilizator varchar(50), @lista_lm int, @ticheteInVenitBrut int, @angajatiPrinDetasare int
	
	if @sesiune<>''
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	else 
		set @utilizator=dbo.fIaUtilizator(null)

	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	set @ticheteInVenitBrut=@parXML.value('(/row/@tichvenitbrut)[1]','int')  
	set @angajatiPrinDetasare=@parXML.value('(/row/@angajatiprindetasare)[1]','int') 
	
--	Date impozit
	if @dataset='I'
	begin
		create table #date
			(data datetime, tip_venit char(2), denumire varchar(1000), nr_beneficiari int, tip_salar char(1), tip_impozit char(1), CNP char(13), nume char(200), tip_functie char(1), 
			venit_brut decimal(10), deduceri_personale decimal(10), deduceri_alte decimal(10), baza_impozit decimal(10), impozit decimal(10), venit_net decimal(10), detalii varchar(max), ordonare varchar(100))

		insert into #date
		exec rapDeclaratia205 @datajos=@datajos, @datasus=@datasus, @tipdecl=0, @tipVenit='010207', @ticheteInVenitBrut=@ticheteInVenitBrut, 
			@contImpozit=null, @contFactura=null, @contImpozitDividende=null, @lm=null, @strict=0, @grupare='', @alfabetic=0, @marca=@marca, 
			@angajatiPrinDetasare=@angajatiPrinDetasare, @cnp=@cnp, @sirDeMarci=null

		select rtrim(dbo.fDenumireLuna(d.data)) as luna, (case when d.tip_functie=1 then 'Functia de baza' else 'In afara fct. de baza' end) as tip_functie, 
		d.venit_brut, d.deduceri_personale, d.deduceri_alte, d.baza_impozit, d.impozit, d.venit_net
		from #date d
	end

--	Date salariat
	if @dataset='S'
	begin
		select p.nume, p.cod_numeric_personal, s.tip_act, convert(char(10),p.Data_nasterii,104) as data_nasterii, s.serie_bul, s.nr_bul, 
			s.elib, s.data_elib, convert(char(10),p.data_angajarii_in_unitate,104) as data_angajarii, p.Localitate, s.adresa, s.judet, 
			isnull((select count(distinct cod_personal) from persintr pe where pe.data between @datajos and @datasus and pe.Marca=p.Marca),0) as nr_persintr, 
			s.den_functie
		from personal p 
			outer apply (select * from fDateSalariati (p.Marca,@dataSus)) s
		where p.marca=@marca or p.cod_numeric_personal=@cnp
		union all 
		select z.nume, z.cod_numeric_personal, 
			(case when upper(left(z.buletin,2))='SX' or charindex('X',z.buletin)<>0 then 'CI' else 'BI' end) as tip_act, convert(char(10),z.Data_nasterii,104) as data_nasterii,
			left(z.buletin,2) as serie_bul, 
			ltrim(substring(z.buletin,3,8)) nr_bul, 
			isnull((select ', eliberat de '+rtrim(val_inf) from extinfop where cod_inf='ELIB' and extinfop.marca=z.marca),'') as elib,
			', la data de '+convert(char(10),z.Data_eliberarii,104) as data_elib,
			convert(char(10),z.data_angajarii,104) as data_angajarii,z.Localitate,
			(case when z.strada<>'' then ' str. ' else '' end)+rtrim(z.strada)+(case when z.numar<>'' then ' nr. ' else '' end)+rtrim(z.numar)
				+(case when z.bloc<>'' then ' bl. ' else '' end)+rtrim(z.bloc)+(case when z.scara<>'' then ' sc: ' else '' end)+rtrim(z.scara) as adresa,
			(case when z.judet<>'' then ' judetul ' else '' end)+rtrim(z.Judet)+(case when z.sector<>0 then ' sector '+rtrim(convert(char(10),z.Sector)) else '' end) as judet, 0 as nr_persintr, 
			rtrim(f.denumire)+' (COR: '+rtrim(cf.Val_inf)+')' as den_functie
		from zilieri z 
			left outer join functii f on z.Cod_functie=f.Cod_functie
			left outer join extinfop cf on cf.Marca=z.Cod_functie
		where (z.marca=@marca or z.cod_numeric_personal=@cnp)
			and not exists (select 1 from personal p where p.marca=@marca or p.cod_numeric_personal=@cnp)
	end

end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (rapAdeverintaDeclaratia205)'
	raiserror(@mesaj, 11, 1)
end catch
