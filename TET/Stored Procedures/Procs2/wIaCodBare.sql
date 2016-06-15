create procedure wIaCodBare   @sesiune varchar(30), @parXML XML
as
begin
declare @cod varchar(20),@cautare varchar(100)
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')
set @cautare=@parXML.value('(/row/@_cautare)[1]','varchar(100)')
set @cautare='%'+isnull(@cautare,'')+'%'

select RTRIM(c.Cod_de_bare) as codbare,
	   rtrim(c.UM) as um,
	   rtrim(case when c.UM='1' then 'BUC' when c.UM='2' then 'CUTIA' when c.UM='3' then 'alt UM' end)  as denum,
	   rtrim(c.UMprodus) as umprodus,
	   rtrim(u.denumire) as denumprodus
from codbare c
left join um u on c.umprodus=u.um
where Cod_produs=@cod
for xml raw
end
