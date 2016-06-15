--***
create Procedure CalcCategBilant @pCateg char(20),@pDataJos datetime,@pDataSus datetime as
declare @cInd char(20),@nFetch int

--delete from expval where cod_indicator in (select cod_ind from compcategorii where cod_categ=@pCateg)


declare tmp cursor for
select cod_ind from compcategorii where cod_categ=@pCateg

open tmp
fetch next from tmp into @cInd
set @nFetch=@@fetch_status
while @nFetch=0
begin
 print 'Calculez '+@cInd
 exec calculInd @cInd,@pDataJos,@pDataJos
 exec calculInd @cInd,@pDataSus,@pDataSus
 fetch next from tmp into @cInd
 set @nFetch=@@fetch_status
end

close tmp
deallocate tmp
