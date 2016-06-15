--***
create procedure LocuriMuncaEXCEL @idRulare int
as

declare @parxml xml, @nivel int, @lm varchar(20), @denumire varchar(20)

select top 1 @parxml=parxml from ASiSRIA..ProceduriDeRulat
where idRulare=@idRulare

select  @nivel=isnull(@parxml.value('(/*/@nivelLM)[1]', 'int'),0),
		@lm=isnull(@parxml.value('(/*/@lmLM)[1]', 'varchar(20)'),''),
		@denumire=isnull(@parxml.value('(/*/@denumireLM)[1]', 'varchar(20)'), '')

if @nivel='' set @nivel=0

select	rtrim(isnull(lm.Nivel, '')) as Nivel, 
		rtrim(isnull(lm.Cod, '')) as Cod, 
		rtrim(isnull(lm.Denumire, '')) as Denumire_loc_munca, 
		rtrim(isnull(lm.Cod_parinte, '')) as Cod_Parinte
from lm
where (@lm='' or lm.Cod like @lm+'%')
	and (@nivel=0 or lm.Nivel<=@nivel) 
	and (@denumire='' or lm.Denumire like '%'+@denumire+'%')
