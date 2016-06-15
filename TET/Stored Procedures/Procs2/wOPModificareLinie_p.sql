
create procedure wOPModificareLinie_p @sesiune varchar(50), @parXML xml
as

declare @meniu varchar(20), @sursa varchar(50), @tip varchar(50), @subtip varchar(50)

select @meniu = @parXML.value('(/row/@meniu)[1]','varchar(20)'),
	@sursa = @parXML.value('(/row/@sursa)[1]','varchar(50)'),
	@tip = isnull(@parXML.value('(/row/@tip_m)[1]','varchar(50)'),''),
	@subtip = isnull(@parXML.value('(/row/@subtip_m)[1]','varchar(50)'),'')
/*set @nume = @parXML.value('(/row/@nume)[1]','varchar(50)')
set @nrordine = isnull(@parXML.value('(/row/@nrordine)[1]','decimal(7,2)'),0)
set @vizibil = isnull(@parXML.value('(/row/@vizibil)[1]','bit'),0)
*/
if @sursa='webconfigmeniu'
select m.Meniu mo_meniu, m.Nume mo_nume, m.NrOrdine mo_nrordine, m.vizibil mo_vizibil
from webconfigmeniu m where meniu=@meniu
for xml raw
else
select m.Meniu mo_meniu, m.Nume mo_nume, m.Ordine mo_nrordine, m.vizibil mo_vizibil, @sursa sursa,
		@tip tip, @subtip subtip
from webconfigtipuri m where meniu=@meniu and isnull(m.tip,'')=@tip and isnull(m.subtip,'')=@subtip
for xml raw
