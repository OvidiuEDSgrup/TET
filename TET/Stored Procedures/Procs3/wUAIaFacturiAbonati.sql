--***
create procedure [dbo].[wUAIaFacturiAbonati] @sesiune varchar(30), @parXML XML
as
begin
Declare @factura varchar(13),@data datetime,@tip varchar(2),@id int,@id_contract int,@datajos datetime,@filtruNr varchar(30),
		@datasus datetime,@filtrufactura varchar(13),@filtruAbonat varchar(13),@utilizator char(10), @userASiS varchar(20),@filtrustrada varchar(30)
select
	@factura = isnull(@parXML.value('(/row/@factura)[1]','varchar(13)'),''),
	@data = isnull(@parXML.value('(/row/@data)[1]','datetime'),'')	,
	@datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
    @datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
	@id = isnull(@parXML.value('(/row/@id)[1]','int'),0),
	--@id_contract = isnull(@parXML.value('(/row/@id_contract)[1]','int'),0),
	@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(3)'),''),
	@filtrufactura = isnull(@parXML.value('(/row/@filtruFactura)[1]','varchar(13)'),''),
	@filtruAbonat = isnull(@parXML.value('(/row/@filtruAbonat)[1]','varchar(13)'),''),
	@filtrustrada = isnull(@parXML.value('(/row/@filtrustrada)[1]','varchar(30)'),''),
    @filtruNr = isnull(@parXML.value('(/row/@filtruNr)[1]','varchar(30)'),''),
	
	@filtruAbonat = (case when @filtruAbonat<>'' then '%'+replace(@filtruAbonat,' ','%')+'%'else '' end),
	@filtrustrada = (case when @filtrustrada<>'' then '%'+replace(@filtrustrada,' ','%')+'%' else '' end),
	@filtruFactura = (case when @filtruFactura<>'' then '%'+replace(@filtruFactura,' ','%')+'%'else '' end)
	
---------
set @Utilizator=dbo.fIauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------

select Top 100 a.*, b.abonat,u.Contract,RTRIM(b.denumire) as denAbonat,rtrim(u.Contract)+' - '+rtrim(b.Denumire) as denContract 
into #AntetFactAbonTemp from AntetFactAbon a 
                     left outer join uacon u on a.id_contract=u.id_contract
                     left outer join abonati b on b.abonat=u.abonat
                     left outer join Strazi s on b.Strada=s.Strada
                     left outer join LMFiltrare lu on lu.utilizator=@utilizator and a.loc_de_munca=lu.cod
where (a.Id_factura=@id or isnull(@id,0)=0)
  and (a.Factura=@factura or isnull(@factura,'')='')	
  and (b.abonat like @filtruAbonat+'%' or b.denumire like '%'+@filtruAbonat+'%' or isnull(@filtruAbonat,'')='')
  and (a.Factura like @filtruFactura+'%' or isnull(@filtruFactura,'')='')
  and (a.Data between @datajos and @datasus) 
  and (@lista_lm=0 or lu.cod is not null) 
  and ((a.Tip=@tip )or(isnull(@tip,'')='') or (@tip='FT') )
  and (s.Denumire_Strada like '%'+@filtrustrada+'%' or isnull(@filtrustrada,'')='')
  and (b.Numar like '%'+@filtruNr+'%' or isnull(@filtruNr,'')='')
  
  order by a.Data desc,a.Factura desc
  
  --select *from #AntetFactAbonTemp

declare @dreptmod int
set @dreptmod=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='ACTFACTGEN' and Valoare='1') then 1 else 0 end)

select  a.id_factura as id,rtrim(a.factura) as factura, rtrim(a.tip) as tip,rtrim(a.abonat) as abonat,rtrim(a.contract) as contract,a.id_contract as id_contract,
        convert(char(10),a.data,101) as data, convert(char(10),a.Data_scadentei,101) as datascadentei,a.tip_tva,
        convert(char(10),a.perioada_inceput,101) as perioada_inceput,convert(char(10),a.perioada_sfarsit,101) as perioada_sfarsit,a.stare,
        convert(char(10),a.perioada_inceput,101) as per_fact_jos,convert(char(10),a.perioada_sfarsit,101) as per_fact_sus,
        isnull(convert(decimal(12,3),f.valoare_factura),0) as valoare,isnull(convert(decimal(12,3),f.sold),0) as sold,
        isnull(convert(decimal(12,3),f.sold_penalizari),0) as sold_pen,isnull(convert(decimal(12,3),f.penalizari),0) as penalizari,
        RTRIM(a.denAbonat) as denAbonat,(case when @tip='AV' or (@tip='FA' and @dreptmod=0) then 1 else 0 end) as _nemodificabil,rtrim(a.denContract) as denContract,
        (case when a.Tip='FA' then 'Factura generata automat' when a.Tip='FM'then 'Factura de mana' when a.Tip='AV' then 'Factura Avans' 
              when a.tip='AP'then 'Factura avans proforma'  when a.tip='IM' then 'Factura implementare' else '' end ) as denTip_doc,
        isnull(convert(decimal(12,3),f.tva),0) as tva,
        a.Id_factura as numar,rtrim(a.abonat) as tert,convert(char(10),a.data,101) as data_facturii
from #AntetFactAbonTemp a left outer join FactAbon f on f.id_factura=a.id_factura
order by a.Data desc,a.Factura desc
for xml raw
drop table #AntetFactAbonTemp
end
--select top 100 * from antetfactabon FactAbon
--exec as login='brantnergrp\asis.test'
--drop table #antetFact
