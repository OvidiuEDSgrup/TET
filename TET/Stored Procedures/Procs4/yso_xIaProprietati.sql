create proc yso_xIaProprietati @tip varchar(20)=null as
select 
	Tip
	,Cod
	,Denumire_cod
	,Cod_proprietate
	,Valoare
	--,Valoare_tupla
from yso_vIaProprietati v
where @tip is null or v.Tip=@tip
