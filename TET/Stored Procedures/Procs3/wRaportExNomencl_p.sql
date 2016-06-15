--***
create procedure wRaportExNomencl_p @sesiune varchar(50), @parXML XML
as
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
set nocount on

select 'NomenclEXCEL' as procedura
for xml raw
