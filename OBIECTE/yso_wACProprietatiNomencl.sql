drop procedure yso_wACCatProprietatiNomencl  
GO
--***
CREATE procedure yso_wACCatProprietatiNomencl  @sesiune varchar(30), @parXML XML
as
declare @codprop varchar(20),@cautare varchar(100), @cod varchar(13), @fltDescriere varchar(80)
select @cod = isnull(@parXML.value('(/row/@cod)[1]','varchar(13)'),'')
	,@cautare=isnull(@parXML.value('(/row/@_cautare)[1]','varchar(200)'),'')
	,@codprop=isnull(@parXML.value('(/row/@codprop)[1]','varchar(20)'),'')

select distinct top 100
	   rtrim(LTRIM(c.descriere)) as denumire,
	   rtrim(c.Cod_proprietate) as cod
	   from tipproprietati t
		inner join catproprietati c on c.Cod_proprietate=t.Cod_proprietate	
		where t.Tip='NOMENCL' and (@codprop='' or c.Cod_proprietate=@codprop)
for xml raw


