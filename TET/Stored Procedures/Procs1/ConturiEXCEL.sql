--***
create procedure ConturiEXCEL @idRulare int
as

declare @parxml xml, @tip varchar(20), @cont varchar(20), @atribuire varchar(20)

select top 1 @parxml=parxml from ASiSRIA..ProceduriDeRulat
where idRulare=@idRulare

select  @tip=isnull(@parxml.value('(/*/@tipcontC)[1]', 'varchar(20)'),''),
		@cont=isnull(@parxml.value('(/*/@contC)[1]', 'varchar(20)'),''),
		@atribuire=isnull(@parxml.value('(/*/@atribuireC)[1]', 'varchar(20)'),'')

select  rtrim(isnull(c.Cont, '')) as Cont,
		rtrim(isnull(c.Denumire_cont, '')) as Denumire_cont,
		(case c.Tip_cont when 'A' then 'Activ' when 'P' then 'Pasiv' when 'B' then 'Bifunctional' else '' end) as Tip_cont,
		rtrim(isnull(c.Cont_parinte, '')) as Cont_parinte,
		(case when c.Are_analitice=1 then 'Da' else 'Nu' end) as Are_analitice,
		isnull(dbo.denAtribuireConturi(c.Sold_credit), '') as Atribuire,
		rtrim(isnull(a.Denumire, '')) as Articol_de_calculatie,
		rtrim(isnull(pr.Valoare, '')) as Valuta
from conturi c
left outer join proprietati pr on pr.Tip='CONT' and pr.Cod_proprietate='INVALUTA' and pr.Cod=c.Cont
left join artcalc a on a.Articol_de_calculatie=c.Articol_de_calculatie
where (@tip='' or c.Tip_cont=@tip)
	and (@cont='' or c.Cont like @cont+'%')
	and (@atribuire='' or c.Sold_credit=@atribuire)
