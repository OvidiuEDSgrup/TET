--***
Create procedure wIaCodProprietati   @sesiune varchar(30), @parXML XML
as
declare @cod varchar(20),@cautare varchar(100)
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')
set @cautare=@parXML.value('(/row/@_cautare)[1]','varchar(100)')
set @cautare='%'+isnull(@cautare,'')+'%'

select distinct 
       @cod as cod,
       rtrim(p.Cod_proprietate) as codprop,
	   RTRIM(cp.descriere) as descriere,
	   RTRIM(p.Valoare) as valoare
	   from proprietati p
		inner join catproprietati cp on cp.Cod_proprietate=p.Cod_proprietate and p.Tip='NOMENCL' AND P.cod=@cod
	   where rtrim(p.Cod_proprietate) like @cautare or @cautare=''
for xml raw
 
