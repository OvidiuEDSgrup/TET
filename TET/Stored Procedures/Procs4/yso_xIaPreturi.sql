create proc yso_xIaPreturi @tip varchar(20)=null as
select 
	cod
	,dencod
	,catpret
	,dencategpret
	,tippret
	,dentippret
	,data_inferioara
	,data_superioara
	,pret_vanzare
	,pret_cu_amanuntul
from yso_vIaPreturi v
