if OBJECT_ID('tempdb..#gesttransfer') is null
	begin
		create table #gesttransfer(gestiune varchar(20),gestiune_transfer varchar(20),nrordine int)
		exec creeazaGestiuniTransfer
	end
	
	select * from #gesttransfer g where g.gestiune like '%nt'