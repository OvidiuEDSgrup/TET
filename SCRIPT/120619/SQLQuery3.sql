--codul 10800044,codintrare IMPL1A,din gest 300(TE REZ00014,AP 115602,TE REZ00517)
declare @cod varchar(20)
select @cod='10800044'
	,@cod='01425500'
select p.Factura,p.Contract
,p.Gestiune,p.Cod_intrare
,p.Gestiune_primitoare,p.Grupa
,* from pozdoc p where p.Cod like @cod and 'IMPL1A' in (p.Cod_intrare,p.Grupa) order by p.data
select * from stocuri s where s.Cod_gestiune='300' and s.Cod like @cod and s.Cod_intrare like 'IMPL1%'
select * from istoricstocuri s where s.Cod_gestiune='300' and s.Cod like @cod and s.Cod_intrare like 'IMPL1%'