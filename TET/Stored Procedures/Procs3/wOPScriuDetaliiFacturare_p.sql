--***
create procedure [dbo].[wOPScriuDetaliiFacturare_p] @sesiune varchar(50), @parXML xml 
as  
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPScriuDetaliiFacturare_pSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPScriuDetaliiFacturare_pSP @sesiune, @parXML output
	return @returnValue
end
declare @factura varchar(13),@nume_delegat varchar(30),@seria_buletin varchar(10),@numar_buletin varchar(10),
	@eliberat varchar(30),@mijloc_de_transport varchar(30),@numarul_mijlocului varchar(13),@data_expedierii datetime,
	@ora_expedierii varchar(6),@observatii varchar(200),@explicatii_anexaf varchar(200),@update bit,@datadoc datetime,@codMeniu varchar(2),
	@tert varchar(20),@descriere varchar(20),@explicatii_anexad varchar(200)


select	@factura=isnull(@parXML.value('(/row/@factura)[1]','varchar(13)'),''),
	@update=isnull(@parXML.value('(/row/@update)[1]','bit'),0),
	@datadoc=isnull(@parXML.value('(/row/@datafacturii)[1]','datetime'),''),
	@codMeniu=isnull(@parXML.value('(/row/@codMeniu)[1]','varchar(2)'),''),
	@tert=isnull(@parXML.value('(/row/@tert)[1]','varchar(20)'),'')

if @codMeniu='TT'--specific pragmatic
 select @factura=isnull(@parXML.value('(/row/@numar)[1]','varchar(13)'),''),
    @datadoc=isnull(@parXML.value('(/row/@data)[1]','datetime'),'')

select @nume_delegat=rtrim(numele_delegatului),@seria_buletin=rtrim(seria_buletin),@numar_buletin=rtrim(numar_buletin),@eliberat=rtrim(eliberat),@mijloc_de_transport=rtrim(mijloc_de_transport),
   @numarul_mijlocului=rtrim(numarul_mijlocului),@data_expedierii=convert(char(10),data_expedierii,101),@ora_expedierii=ltrim(ora_expedierii),
   @explicatii_anexaf=rtrim(observatii),@explicatii_anexad=rtrim(observatii)
from anexadoc where Numar=@factura and data=@datadoc

select @explicatii_anexaf=rtrim(observatii)
from anexafac where Numar_factura=@factura

if @update=1
	return
	
if @codMeniu='AA'--specific pragmatic
begin
	set @descriere=(select Descriere from infotert where Subunitate='C1' and tert=@tert and Identificator=@nume_delegat)
	set @nume_delegat=(case when exists (select 1 from infotert where Subunitate='C1' and tert=@tert and Identificator=@nume_delegat)
						then @descriere else @nume_delegat end)
end					
	
select @factura factura,@nume_delegat numele_delegatului,@seria_buletin seria_buletin,@numar_buletin numar_buletin,@eliberat eliberat,
   @mijloc_de_transport mijloc_de_transport	,@numarul_mijlocului numarul_mijlocului,convert(char(10),@data_expedierii,101) data_expedierii,
   (case when isnull(rtrim(@ora_expedierii),'')='' then rtrim(convert(char(5),getdate(),108)) else @ora_expedierii end) ora_expedierii,
   @explicatii_anexaf explicatii_anexaf, @explicatii_anexad explicatii_anexad
for xml raw
