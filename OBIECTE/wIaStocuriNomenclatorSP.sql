--***
if exists (select * from sysobjects where name ='wIaStocuriNomenclatorSP')
drop procedure wIaStocuriNomenclatorSP
go
--***
Create procedure wIaStocuriNomenclatorSP   @sesiune varchar(30), @parXML XML
as /*SP
if exists(select * from sysobjects where name='wIaStocuriNomenclatorSP' and type='P')
	exec wIaStocuriNomenclatorSP @sesiune, @parXML 
else   --SP*/   
begin

Declare @iDoc int

Declare @cSub varchar(9), @cod varchar(20), @cautare varchar(100)
exec luare_date_par 'GE','SUBPRO',1,0,@cSub OUTPUT
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')
Set @cautare = @parXML.value('(/row/@_cautare)[1]','varchar(100)')

select  rtrim(s.tip_gestiune) as tip, rtrim(s.cod_gestiune) as gestiune, convert(decimal(15,5),s.pret) as pret,
convert(char(10),s.data,101) as data, convert(decimal(12,3),s.stoc) as stoc, RTRIM(s.cont) as cont, RTRIM(s.cod_intrare) as codintrare ,
rtrim(s.cod_gestiune)+'-'+RTRIM(g.Denumire_gestiune) as dengestiune,
rtrim(t.Tert)+'-'+RTRIM(t.Denumire) as dentert --/*SP
,locatie=rtrim(s.Locatie)--SP*/
from stocuri s
inner join gestiuni g on s.Cod_gestiune=g.Cod_gestiune
left outer join terti t on s.Locatie=t.tert
where s.Subunitate = @cSub and s.Cod = @cod and s.Stoc <> 0
	and (isnull(@cautare,'')='' or s.cod_gestiune like '%'+@cautare+'%')
order by s.Data
for xml raw
end