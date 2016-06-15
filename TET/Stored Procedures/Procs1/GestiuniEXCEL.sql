--***
create procedure GestiuniEXCEL @idRulare int
as

declare @parxml xml, @tipgestiune varchar(20), @gestiune varchar(20), @denumire varchar(80), @cont varchar(20), @lm varchar(20)

select top 1 @parxml=parxml from ASiSRIA..ProceduriDeRulat
where idRulare=@idRulare

select  @tipgestiune=isnull(@parxml.value('(/*/@tipgestiuneG)[1]', 'varchar(20)'),''),
		@gestiune=isnull(@parxml.value('(/*/@gestiuneG)[1]', 'varchar(20)'), ''),
		@denumire=isnull(@parxml.value('(/*/@denumireG)[1]', 'varchar(80)'),''),
		@cont=isnull(@parxml.value('(/*/@contG)[1]', 'varchar(20)'),''),
		@lm=isnull(@parxml.value('(/*/@lmG)[1]', 'varchar(20)'),'')

select  isnull(dbo.denTipGestiune(g.Tip_gestiune), '') as Tip_gestiune,
		rtrim(isnull(g.Cod_gestiune, '')) as Cod_gestiune, 
		rtrim(isnull(g.Denumire_gestiune, '')) as Denumire_gestiune, 
		rtrim(isnull(g.Cont_contabil_specific, '')) as Cont_contabil_specific,
		rtrim(isnull(g.detalii.value('(/row/@lm)[1]', 'varchar(20)'), '')) as Cod_loc_munca,
		rtrim(isnull(lm.Denumire, '')) as Loc_munca
from gestiuni g
left join lm on lm.Cod=g.detalii.value('(/row/@lm)[1]', 'varchar(20)')
where (@tipgestiune='' or g.Tip_gestiune=@tipgestiune)
	and (@gestiune='' or g.Cod_gestiune like @gestiune+'%')
	and (@denumire='' or g.Denumire_gestiune like '%'+@denumire+'%')
	and (@cont='' or g.Cont_contabil_specific like @cont+'%')
	and (@lm='' or g.detalii.value('(/row/@lm)[1]', 'varchar(20)')=@lm)
