create procedure  [dbo].[wACStariAngajamenteBugetare] @sesiune varchar(50), @parXML XML
as
select  convert (varchar(1),'0') as cod , '0-Propunere' as denumire
union all
select  convert (varchar(1),'1') , '1-Viza prop.' 
union all
select convert (varchar(1),'4'),'4-Respins'
union all
select convert (varchar(1),'5'), '5-Angajare bugetara'
union all
select convert (varchar(1),'6'), '6-Viza angajare'
       
for xml raw
