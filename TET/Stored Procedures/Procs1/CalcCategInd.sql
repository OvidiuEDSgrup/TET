--***
CREATE procedure [dbo].[CalcCategInd] @pCateg char(20),@pDataJos datetime,@pDataSus datetime,@lTipSold  int,@lFaraStergere bit=0  
as  
declare @cInd char(20),@nFetch int  
--Declare @cHostID char(8)  
--set @cHostID = convert(char(8),abs(convert(int, host_id())))  

if @lFaraStergere=0  
	--delete from tmp_calculat where hostid=@cHostID  
	truncate table tmp_calculat
  
if exists (select 1 from indicatori i inner join compcategorii c on c.cod_ind=i.cod_indicator where c.cod_categ=@pcateg and charindex('infftrt',expresia)<>0)
begin	--> infftrt este o tabela sinteza cu facturile pe terti; infftrt se foloseste ca sa nu ia mult timp calculul (cum s-ar intampla daca s-ar apela fFacturi pt fiecare indicator in parte)
if exists (select 1 from sysobjects where xtype='U' and name='infftrt') 
drop table infftrt create table infftrt (fb char(1),tip varchar(2),tert varchar(13),factura varchar(20),cont_coresp varchar(20))
	insert into infftrt (fb,tip,tert,factura,cont_coresp) 
	select 'F' as fb,tip,tert,factura,cont_coresp 
		from fFacturi ('f','1901-1-1','2100-1-1',null,null,null,0,0,0, null, null) f group by tip,tert,factura,cont_coresp union all 
	select 'B' as fb,tip,tert,factura,cont_coresp 
		from fFacturi ('b','1901-1-1','2100-1-1',null,null,null,0,0,0,null, null) f group by tip,tert,factura,cont_coresp
end

declare tmp cursor for  
select cod_ind from compcategorii where cod_categ=@pCateg  
  
open tmp  
fetch next from tmp into @cInd  
set @nFetch=@@fetch_status  
while @nFetch=0  
begin  
	-- print 'Calculez '+@cInd  
	If @lTipSold=0 -- caz general
		exec calculInd @cInd,@pDataJos,@pDataSus  
	Else -- caz bilant: Daca se foloseste pentru calcul sold (bilant) se vor calcula valorile doar la data jos si data sus si nu pt. tot intervalul  
	Begin  
		exec calculInd @cInd,@pDataJos,@pDataJos  
		delete from tmp_calculat where /*hostid=@cHostId and*/ cod=@cInd  
		exec calculInd @cInd,@pDataSus,@pDataSus  
	End  
	  
	fetch next from tmp into @cInd  
	set @nFetch=@@fetch_status  
end  
  
exec dbo.corect_expval

close tmp  
deallocate tmp
