/****** Object:  StoredProcedure [dbo].[wUAIaNomenclabon]    Script Date: 01/05/2011 23:51:25 ******/
--***
create PROCEDURE [dbo].[wUAIaNomenclabon] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
set transaction isolation level READ UNCOMMITTED

 Declare  @filtrucodserv varchar(8),@filtrudenserv varchar(30),@utilizator char(10), @userASiS varchar(20)
select 
   @filtrucodserv = isnull(@parXML.value('(/row/@filtrucodserv)[1]','varchar(20)'),''), 
   @filtrudenserv = isnull(@parXML.value('(/row/@filtrudenserv)[1]','varchar(30)'),'') 
   
---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------

select top 100 (case when @filtrucodserv<>'' then space(20-LEN(a.cod))+a.cod else '' end) as o,rtrim(a.cod) as cod,rtrim(a.denumire) as denumire,isnull(RTRIM(b.Denumire),'') as denum,RTRIM(a.um) as um, 
convert(decimal(15, 2), a.tarif) as tarif,convert(decimal(5, 0), a.cota_tva) as cotatva,
rtrim(a.tip_serviciu) as tipserviciu,rtrim(e.denumire_serviciu) as denserviciu ,rtrim(a.cont_venituri) as contvenituri,RTRIM(d.denumire_cont) as dencont,
RTRIM(a.comanda) as comanda,rtrim(c.descriere) as dencomanda,rtrim(a.loc_de_munca) as lm,rtrim(f.denumire) as denlm
from NomenclAbon a 
left outer join um b on a.UM=b.um 
left outer join comenzi c on a.comanda=c.comanda
left outer join conturi d on a.Cont_venituri=d.cont
left outer join Tipuri_de_servicii e on a.Tip_serviciu=e.cod_serviciu
left outer join lm f on a.loc_de_munca=f.cod
left outer join LMFiltrare lu on lu.utilizator=@utilizator and a.loc_de_munca=lu.cod
where (a.cod like '%'+@filtrucodserv+'%' or @filtrucodserv='') 
	and (a.denumire like '%'+@filtrudenserv+'%' or @filtrudenserv='')
	and (@lista_lm=0 or lu.cod is not null)
order by  o, patindex('%'+@filtrudenserv+'%', a.denumire), a.denumire
for xml raw
