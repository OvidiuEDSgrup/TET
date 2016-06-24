﻿--***
CREATE procedure [dbo].[wACCatProprietatiTerti]   @sesiune varchar(30), @parXML XML
as
declare @codprop varchar(20),@cautare varchar(100), @tert varchar(13), @fltDescriere varchar(80)
select @tert = isnull(@parXML.value('(/row/@tert)[1]','varchar(13)'),'')
	,@cautare=isnull(@parXML.value('(/row/@_cautare)[1]','varchar(200)'),'')
	,@codprop=isnull(@parXML.value('(/row/@codprop)[1]','varchar(20)'),'')

select distinct top 100
	   rtrim(LTRIM(c.descriere)) as denumire,
	   rtrim(c.Cod_proprietate) as cod
	   from tipproprietati t
		inner join catproprietati c on c.Cod_proprietate=t.Cod_proprietate	
		where t.Tip='TERT' and (@codprop='' or c.Cod_proprietate=@codprop)
for xml raw
