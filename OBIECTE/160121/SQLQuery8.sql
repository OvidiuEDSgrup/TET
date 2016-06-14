execute AS login='tet\magazin.nt'
begin tran
--/*
select * --*/delete p 
 from pozdoc p where p.Tert='1720906270600' and 
p.Cod in ('VB-060504-B','VB-060504-R')
exec wDescarcBon null,'<row idAntetBon="13506" />'
if @@TRANCOUNT >0 
	rollback tran
revert