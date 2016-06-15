--***
create procedure NomenclEXCEL @idRulare int
as
	
declare @parxml xml, @tip varchar(20), @grupa varchar(20), @denumire varchar(80)

select top 1 @parxml=parxml from ASiSRIA..ProceduriDeRulat
where idRulare=@idRulare

select  @tip=isnull(@parxml.value('(/*/@tipN)[1]', 'varchar(20)'),''),
		@denumire = replace(isnull(@parXML.value('(/*/@denumireN)[1]','varchar(80)'),''), ' ', '%'),
		@grupa=isnull(@parxml.value('(/*/@grupaN)[1]', 'varchar(20)'),'')

select  rtrim(isnull(n.Cod, '')) as Cod, 
		rtrim(isnull(n.Denumire, '')) as Denumire, 
		isnull(dbo.denTipNomenclator(n.tip), '') as Tip, 
		rtrim(isnull(n.Cont, '')) as Cont, 
		rtrim(isnull(g.Grupa, '')) as Grupa, 
		rtrim(isnull(g.Denumire, '')) as Denumire_grupa,
		rtrim(isnull(sl.Stoc_min, 0)) as Stoc_minim,
		rtrim(isnull(n.Greutate_specifica, '')) as Greutate_specifica

from nomencl n
left join grupe g on n.grupa=g.grupa
left join stoclim sl on sl.Cod=n.Cod
where (@tip='' or n.tip=@tip )
	and (@denumire='' or n.Denumire like '%'+@denumire+'%')
	and (@grupa='' or g.grupa=@grupa)
