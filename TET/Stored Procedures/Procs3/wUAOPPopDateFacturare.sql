--***
/* model pentru populare macheta tip 'formular' - adaugare/modificare in cataloage si operatii */
create procedure [dbo].[wUAOPPopDateFacturare] @sesiune varchar(50), @parXML xml 
as  

declare @id_factura int,@nume_delegat varchar(30),@seria_buletin varchar(10),@numar_buletin varchar(10),
        @eliberat varchar(30),@mijloc_de_transport varchar(30),@numarul_mijlocului varchar(13),@data_expedierii date,
        @ora_expedierii varchar(6),@observatii varchar(200),@explicatii varchar(100),@update bit


select	@id_factura=isnull(@parXML.value('(/row/@id)[1]','int'),0),
		@update=isnull(@parXML.value('(/row/@update)[1]','bit'),0)
		
--select @id_factura
select @nume_delegat=rtrim(numele_delegatului),@seria_buletin=rtrim(seria_buletin),@numar_buletin=rtrim(numar_buletin),@eliberat=rtrim(eliberat),@mijloc_de_transport=rtrim(mijloc_de_transport),
	   @numarul_mijlocului=rtrim(numarul_mijlocului),@data_expedierii=convert(char(10),data_expedierii,101),@ora_expedierii=rtrim(ora_expedierii),
	   @observatii=rtrim(observatii),@explicatii=rtrim(explicatii)
from uaanexafac where id_factura=@id_factura

if @update=1
	return

select @id_factura id_factura,@nume_delegat numele_delegatului,@seria_buletin seria_buletin,@numar_buletin numar_buletin,@eliberat eliberat,
	   @mijloc_de_transport mijloc_de_transport	,@numarul_mijlocului numarul_mijlocului,convert(char(10),@data_expedierii,101) data_expedierii,
	   @ora_expedierii ora_expedierii,@observatii observatii,@explicatii explicatii
for xml raw

--select * from uaanexafac
