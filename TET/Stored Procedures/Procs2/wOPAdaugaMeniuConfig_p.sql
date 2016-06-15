
create procedure wOPAdaugaMeniuConfig_p @sesiune varchar(50), @parXML xml
as

declare @meniu varchar(200), @sursa varchar(200)
select @meniu=@parXML.value('(/row/@meniu)[1]','varchar(20)'),
		@sursa=@parXML.value('(/row/@sursa)[1]','varchar(20)')

--/*		
select w.meniu, w.Nume nume, w.MeniuParinte parinte, w.TipMacheta tip_macheta,
		w.NrOrdine nrordine, w.Icoana icoana, w.vizibil, 0 as modificabil, w.meniu as o_meniu,
		@sursa sursa
from webconfigmeniu w where meniu=@meniu
for xml raw
--*/
