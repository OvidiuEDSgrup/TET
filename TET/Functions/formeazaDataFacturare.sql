CREATE function formeazaDataFacturare(@periodicitate int,@contract varchar(20), @tip varchar(2),@cod  varchar(20), @datacon datetime, @tert varchar(20))        
returns @termenePrelucrate table(subunitate varchar(10), tip varchar(2), contract varchar(20), tert varchar(13), data datetime,
								 cod varchar(20), termen datetime ,datafacturare datetime, cantitate float, cant_realizata float, explicatii varchar(200), val1 float,val2 float,pret float,	 perioadaFact int)
as 
begin
 

declare @areDetalii int
if exists(select 1 from syscolumns sc,sysobjects so where so.id=sc.id and so.name='con' and sc.name='detalii')
	set @areDetalii=1
else
	set @areDetalii=0

declare @termen datetime , @datainceputcontract datetime, @n int, @nrtermene int, @data datetime, @perioadaFact int, @contractPrelucr varchar(30)
set @n=0
set @nrtermene=0
declare formareTermene cursor for 
select t.termen , t.CONTRACT, t.tip, t.tert,
(case when @areDetalii=1 then 1 --c.detalii.value('(/row/@periodicitate)[1]','int') 
	else null end) as perioadaFact 
from termene t 
inner join con c on c.subunitate=t.subunitate and c.Tert=t.tert and c.Contract=t.contract 
where	(t.contract =@contract or isnull(@contract,'')='') and (t.tip=@tip or isnull(@tip,'')='') and 
														(t.tert=@tert or isnull(@tert,'')='') and (t.data=@datacon or isnull(@datacon,'')='') and 
														(t.cod=@cod or isnull(@cod,'')='')
open formareTermene
fetch next from formareTermene into @termen, @contractPrelucr,@tip,@tert,@perioadaFact
while @@FETCH_STATUS=0
begin
	--daca parcurg prima linie din termene atunci determin datainceputcontract= primul termen din contract al codului asociat. 
	if @nrtermene<1	
		set @datainceputcontract=(select top 1 termen from termene where (contract =@contract  or contract=@contractPrelucr) and (data=@datacon  or isnull(@datacon,'')='') and (cod=@cod or isnull(@cod,'')='')order by termen asc) 
	-----------------
	--numar cate linii sunt pe termene astfel incat atunci cand am nr impar de termene pe cod la sf parcurgerii sa pot initializa @n=0(-ma ajuta la determinarea datei de facturare in functie de periodicitate)
	if @nrtermene+1=(select count(*) from termene where (contract =@contract  or contract=@contractPrelucr) and (data=@datacon  or isnull(@datacon,'')='') and (cod=@cod or isnull(@cod,'')=''))
		set @nrtermene=0 
	else
		set @nrtermene=@nrtermene+1
	if @nrtermene=1 
		set @n=0
	-------------------------------------------------------------------------
	--------adaptare pentru apelare cu parametrii expliciti sau nu(specific proc wIaRealiz, wIaPozRealiz)	
if (@periodicitate='1'  or @perioadaFact='1')
	set @periodicitate='3'
else if (@periodicitate='2' or @perioadaFact='2')
	set @periodicitate='6'
 else if (@periodicitate='3' or @perioadaFact='3')
	set @periodicitate='12'
	----------------------------------------
	-------cand @n este egal cu periodicitatea contractului atunci termenul curent sa ii atribuie valoarea @datainceputcontract(care are 2 utilizari 1. pt determinarea inceput contract 2. pentru det datei de facturare.)
	if @n=@periodicitate
		begin
			set @datainceputcontract=@termen
			set @n=0 
		end
 set @n=@n+1
 insert into @termenePrelucrate(subunitate , tip , contract , tert , data , cod , termen ,datafacturare , cantitate , cant_realizata , explicatii , val1, val2 , pret, perioadaFact)
					select top 1 subunitate, tip, contract, tert, data, cod, @termen, @datainceputcontract, cantitate, Cant_realizata, explicatii, val1, val2,pret,  @perioadaFact from termene 
					where (contract =@contract  or contract=@contractPrelucr )and (tip=@tip or isnull(@tip,'')='') and (termen=@termen or @termen='') and
														(tert=@tert or isnull(@tert,'')='') and (data=@datacon or isnull(@datacon,'')='') and 
														(cod=@cod or isnull(@cod,'')='')
	order by termen asc
fetch next from formareTermene into  @termen, @contractPrelucr,@tip,@tert,@perioadaFact
end
close formareTermene
deallocate formareTermene 

return
end
