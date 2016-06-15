--***
create procedure situatie @cod_categ char(20),@dataJ datetime,@dataS datetime,@nCalcul int as
declare @el1 char(30),@ci char(20),@nFetch int
set @el1=null

if @nCalcul=1
begin
 declare tmp cursor for
 select cod_ind from compcategorii where cod_categ=@cod_categ
 open tmp
 fetch next from tmp into @ci
 set @nFetch=@@fetch_status
 while @nFetch=0
 begin
  fetch next from tmp into @ci
  set @nFetch=@@fetch_status
  exec calculInd @ci,@DataJ,@dataS
 end
 close tmp
 deallocate tmp
end
select c.rand,i.expresie,i.cod_indicator,i.denumire_indicator,e.data,e.element_1,e.element_2,
e.element_3,e.element_4,e.element_5,
e.valoare
from indicatori i
full join compcategorii c on c.cod_ind=i.cod_indicator
left outer join expval e on i.cod_indicator=e.cod_indicator and (@el1 is null or e.element_1=@el1) and data in(@dataJ,@dataS)
where i.cod_indicator in (select cod_ind from compcategorii where cod_categ=@cod_categ)
order by rand
