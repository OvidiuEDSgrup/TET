/****** Object:  StoredProcedure [dbo].[wUAIaPozFacturiAbonati]    Script Date: 01/05/2011 23:51:25 ******/
--***
create procedure  [dbo].[wUAIaPozFacturiAbonati]  @sesiune varchar(30), @parXML XML
as

Declare @id int,@tip varchar(2),@factura varchar(13),@data datetime
select
	@id = isnull(@parXML.value('(/row/@id)[1]','int'),0),
	@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(3)'),'')	

declare @dreptmod int,@Utilizator char(10)
set @Utilizator=dbo.fIauUtilizatorCurent()  
set @dreptmod=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='ACTFACTGEN' and Valoare='1') then 1 else 0 end)	
select  p.id_factura as id,p.nr_pozitie, rtrim(p.cod) as cod,
        isnull(convert(decimal(12,3),p.cantitate),0) as cantitate,isnull(convert(decimal(12,3),p.Tarif),0) as tarif,
        isnull(convert(decimal(12,3),p.Cota_TVA),0) as cota_tva,(case when @tip<>'AV' then convert(decimal(12,3),p.tarif*p.cantitate) else 0 end )as valoare_fara_tva,
        RTRIM(p.loc_de_munca) as lm,RTRIM(p.comanda) as comanda,rtrim(c.Denumire) as denCod,(case when @tip<>'AV' then convert(decimal(12,3),p.tarif*p.cantitate*p.cota_tva/100)else 0 end) as TVA,
        (case when (@tip in ('AV','AP','IM') or (@tip='FA' and @dreptmod=0))then 1 else 0 end) as _nemodificabil,@tip as subtip,rtrim(lm.Denumire) as denLm,
        rtrim(c.denumire) as denServiciu

from pozitiifactabon p left outer join NomenclAbon AS c ON c.Cod = p.Cod
                       left outer join lm on p.Loc_de_munca=lm.Cod
where Id_factura=@id

for xml raw
--select * from pozitiifactabon
