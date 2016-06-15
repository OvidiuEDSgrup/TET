--***
CREATE procedure [dbo].wmAlegCodDispReceptie @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmAlegCodDispReceptieSP' and type='P')
begin
	exec wmAlegCodDispReceptieSP @sesiune, @parXML 
	return -1
end

declare @utilizator varchar(50)
set transaction isolation level READ UNCOMMITTED

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null 
	return -1

if @parXML.exist('(/row/@wmNomenclator.procdetalii)[1]')=1
	set @parXML.modify('replace value of (/row/@wmNomenclator.procdetalii)[1] with "wmScriuWPozReceptii"')                     
else           
	set @parXML.modify ('insert attribute wmNomenclator.procdetalii {"wmScriuWPozReceptii"} into (/row)[1]') 

if @parXML.exist('(/row/@wmNomenclator.tipdetalii)[1]')=1
	set @parXML.modify('replace value of (/row/@wmNomenclator.tipdetalii)[1] with "D"')                     
else           
	set @parXML.modify ('insert attribute wmNomenclator.tipdetalii {"D"} into (/row)[1]') 

if @parXML.exist('(/row/@wmNomenclator.meniuDetalii)[1]')=1
	set @parXML.modify('replace value of (/row/@wmNomenclator.meniuDetalii)[1] with "MD"')                     
else           
	set @parXML.modify ('insert attribute wmNomenclator.meniuDetalii {"MD"} into (/row)[1]') 

exec wmNomenclator @sesiune=@sesiune,@parXML=@parXML


