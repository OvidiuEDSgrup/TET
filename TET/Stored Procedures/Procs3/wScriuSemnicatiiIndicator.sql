--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori )- adauga semnificatii datelor unui indicatori */

CREATE procedure  wScriuSemnicatiiIndicator  @sesiune varchar(50), @parXML XML
as
declare @codInd varchar(10), @limita varchar(10), @seminific varchar(50), @update varchar(1), @count int, @o_limita varchar(10), @o_semnific varchar(50)

		

set	@update = rtrim(isnull(@parXML.value('(/row/row/@update)[1]', 'varchar(1)'), ''))
set	@codInd = rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(10)'), ''))
set	@limita = rtrim(isnull(@parXML.value('(/row/row/@valmax)[1]', 'varchar(10)'), ''))
set	@seminific = rtrim(isnull(@parXML.value('(/row/row/@semnificatie)[1]', 'varchar(50)'), ''))
set @o_semnific = rtrim(isnull(@parXML.value('(/row/row/row/@semnificatie)[1]', 'varchar(50)'), ''))
set @o_limita = rtrim(isnull(@parXML.value('(/row/row/row/@valmax)[1]', 'varchar(10)'), ''))

set @count= (select COUNT(*) from semnific where indicator=@codInd)
if (@update <> '1')
begin
	if (@count = 3)
		RAISERROR('Nu este posibila adaugarea a mai mult de 3 semnificatii',16,1)	
	else
		insert into semnific values ( @codInd,1,@limita,@seminific,'',0)	
end
else
	update semnific set Val_max=@limita, Semnificatie=@seminific where Val_max=@o_limita and Semnificatie=@o_semnific