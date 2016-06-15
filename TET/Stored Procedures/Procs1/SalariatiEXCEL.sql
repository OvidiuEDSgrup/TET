--***
create procedure SalariatiEXCEL @idRulare int
as

declare @parxml xml, @nume varchar(80), @functie varchar(20), @lm varchar(20)

select top 1 @parxml=parxml from ASiSRIA..ProceduriDeRulat
where idRulare=@idRulare

select  @nume=isnull(@parxml.value('(/*/@numeS)[1]', 'varchar(80)'),''),
		@functie=isnull(@parxml.value('(/*/@functieS)[1]', 'varchar(20)'),''),
		@lm=isnull(@parxml.value('(/*/@lmS)[1]', 'varchar(20)'),'')

select
	rtrim(isnull(p.marca, '')) as Marca,
	rtrim(isnull(p.nume, '')) as Nume_salariat,
	rtrim(isnull(p.cod_functie, '')) as Functie, 
	rtrim(isnull(f.denumire, '')) as Denumire_functie,
	convert(decimal(10),isnull(p.salar_lunar_de_baza, 0)) as Regim_lucru,
	rtrim(isnull(p.loc_de_munca, '')) as Loc_munca, 
	rtrim(isnull(lm.denumire, '')) as DenLoc_munca,
	convert(decimal(10), isnull(p.salar_de_incadrare, 0)) as Salar_incadrare,
	convert(decimal(10), isnull(p.salar_de_baza, 0)) as Salar_baza
from personal p
left join functii f on p.cod_functie=f.cod_functie
left join lm on p.loc_de_munca=lm.cod
left join categs csal on csal.Categoria_salarizare=p.Categoria_salarizare
where (@nume='' or p.Nume like '%' + @nume + '%')
	and (@functie='' or p.cod_functie=@functie)
	and (@lm='' or p.Loc_de_munca like @lm+'%')
