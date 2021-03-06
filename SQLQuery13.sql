/****** Object:  StoredProcedure [dbo].[wIaPreturiNomenclator]    Script Date: 04/28/2012 15:53:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--***
ALTER procedure [dbo].[wIaPreturiNomenclator]   @sesiune varchar(30), @parXML XML
as
begin
declare @cod varchar(20),@cautare varchar(100), @lista_categpret int
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')
set @cautare=@parXML.value('(/row/@_cautare)[1]','varchar(100)')
set @cautare='%'+isnull(@cautare,'')+'%'
set @lista_categpret=(case when exists (select 1 from fPropUtiliz() where cod_proprietate='CATEGPRET' and valoare<>'')then 1 else 0 end)
select rtrim(cod_produs) as cod,
rtrim(categorie) as catpret,
rtrim(cp.Denumire) as 'dencategpret',
rtrim(p.tip_pret) as tippret,
dtp.denumire as dentippret,
convert(char(10),data_inferioara,101) as data_inferioara,
convert(char(10),data_superioara,101) as data_superioara,
rtrim(convert(decimal(12,3),Pret_vanzare)) as pret_vanzare,
rtrim(convert(decimal(12,3),Pret_cu_amanuntul)) as pret_cu_amanuntul
from preturi p
inner join categpret cp on p.UM=cp.Categorie
inner join dbo.fTipPret() dtp on p.tip_pret=dtp.tipPret
left outer join fPropUtiliz() fp on cod_proprietate='CATEGPRET' and categorie=fp.valoare
for xml raw
where p.Cod_produs=@cod
and rtrim(cp.Denumire) like @cautare
and (@lista_categpret=0 OR fp.valoare is not null)
order by convert(char(10),data_inferioara,101) desc
for xml raw
end