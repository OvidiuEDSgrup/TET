--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori )- adauga semnificatii datelor unui indicatori */

CREATE procedure  wStergSemnificatiiIndicator  @sesiune varchar(50), @parXML XML
as
declare @codInd varchar(10), @valmax int

set @codInd= rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(10)'), ''))
set	@valmax= rtrim(isnull(@parXML.value('(/row/row/@valmax)[1]', 'varchar(10)'), ''))

delete from semnific where indicator=@codInd and Val_max=@valmax
