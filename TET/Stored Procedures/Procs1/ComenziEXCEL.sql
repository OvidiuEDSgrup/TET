--***
create procedure ComenziEXCEL @idRulare int
as

declare @parxml xml, @denumire varchar(80), @tipcomanda varchar(20), @stareacomenzii varchar(20)

select top 1 @parxml=parxml from ASiSRIA..ProceduriDeRulat
where idRulare=@idRulare

select  @denumire=isnull(@parxml.value('(/*/@denumireC)[1]', 'varchar(80)'),''),
		@tipcomanda=isnull(@parxml.value('(/*/@tipcomandaC)[1]', 'varchar(20)'),''),
		@stareacomenzii=isnull(@parxml.value('(/*/@stareacomenziiC)[1]', 'varchar(20)'),'')

select	rtrim(isnull(c.Comanda, '')) as Comanda,
		rtrim(isnull(c.Descriere, '')) as Descriere,
		isnull(dbo.denTipComanda(c.Tip_comanda), '') as Tip_comanda,
		rtrim(isnull(convert(varchar(10), convert(datetime, c.Data_lansarii, 103), 103), '')) as Data_lansarii,
		rtrim(isnull(convert(varchar(10), convert(datetime, c.Data_inchiderii, 103), 103), '')) as Data_inchiderii,
		isnull(dbo.denStareComanda(c.Starea_comenzii), '') as Starea_comenzii,
		rtrim(isnull(c.Loc_de_munca, '')) as Loc_de_munca, 
		rtrim(isnull(lm.Denumire, '')) as Denumire_loc_munca		 
from comenzi c
left join lm on lm.Cod=c.Loc_de_munca
where (@denumire='' or c.Descriere like '%'+@denumire+'%')
	and (@tipcomanda='' or c.Tip_comanda=@tipcomanda)
	and (@stareacomenzii='' or c.Starea_comenzii=@stareacomenzii)
