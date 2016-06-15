--***
CREATE procedure [dbo].[wmAlegCod] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmAlegCodSP' and type='P')
begin
	exec wmAlegCodSP @sesiune, @parXML 
	return -1
end

declare @utilizator varchar(50)
set transaction isolation level READ UNCOMMITTED

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null 
	return -1

if @parXML.exist('(/row/@wmNomenclator.procdetalii)[1]')=1
	set @parXML.modify('replace value of (/row/@wmNomenclator.procdetalii)[1] with "wmScriuPozitieComanda"')                     
else           
	set @parXML.modify ('insert attribute wmNomenclator.procdetalii {"wmScriuPozitieComanda"} into (/row)[1]') 

exec wmNomenclator @sesiune=@sesiune,@parXML=@parXML
