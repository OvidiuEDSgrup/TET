--***
create procedure wOPStornareDoc_p @sesiune varchar(50), @parXML xml
as

declare @factura varchar(20), @datadoc datetime,@tert varchar(20),@docsursa varchar(50), @datadocsursa varchar(20), @dentert varchar(20),
		@cod varchar(30), @codi varchar(30), @cantitate decimal(12,2), @numarpoz int


select	@factura=isnull(@parXML.value('(/row/@factura)[1]','varchar(13)'),''),
		@datadoc=isnull(@parXML.value('(/row/@datafacturii)[1]','datetime'),''),
		@tert=isnull(@parXML.value('(/row/@tert)[1]','varchar(20)'),''),
		@cod=ISNULL(@parXML.value('(/row/row/@cod)[1]', 'varchar(20)'), ''),
		@codi=ISNULL(@parXML.value('(/row/row/@codintrare)[1]', 'varchar(20)'), ''),
		@numarpoz=ISNULL(@parXML.value('(/row/row/@numarpozitie)[1]', 'int'), 0),
		@cantitate=ISNULL(@parXML.value('(/row/row/@cantitate)[1]', 'decimal(12,3)'), 0)

if @parXML.exist('/*/row')=0
	select 'Operatia va storna documentul intreg, exista posibilitate de stornare partiala prin selectarea pozitiei documentului!' as textMesaj, 'Atentie' as titluMesaj for xml raw, root('Mesaje')
	else
	select 'Operatia va storna doar pozitia selectata, pentru stornare integrala selectati antetul documentul!' as textMesaj, 'Atentie' as titluMesaj for xml raw, root('Mesaje')



select @tert=RTRIM(d.tert), @docsursa=RTRIM(d.Numar), @datadocsursa=convert(varchar(20),d.Data,101),
	   @cantitate=-1*@cantitate
from pozdoc d  where d.Numar=@factura and d.Data=@datadoc and d.tert=@tert and (cod=@cod or @cod='') and
					(Cod_intrare=@codi or @codi='') and (Numar_pozitie=@numarpoz or @numarpoz='')

select @tert tert_p , @docsursa docsursa, convert(varchar(10),@datadocsursa,101) datasursa, @cod articol, @codi codintrare, @cantitate cantitate
for xml raw

