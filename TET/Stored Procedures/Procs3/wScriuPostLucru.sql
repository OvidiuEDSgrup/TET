--***

CREATE procedure  wScriuPostLucru  @sesiune varchar(50), @parXML XML
as

declare @postlucru int, @o_postlucru int, @locmunca varchar(50),  
	@denumire varchar(50), @consilier varchar(50), @update int

set @consilier= rtrim(isnull(@parXML.value('(/row/@consilier)[1]', 'varchar(10)'), ''))
set @postlucru= rtrim(isnull(@parXML.value('(/row/@postlucru)[1]', 'int'), 0))
set @o_postlucru= rtrim(isnull(@parXML.value('(/row/@o_postlucru)[1]', 'int'), 0))
set	@locmunca = rtrim(isnull(@parXML.value('(/row/@locmunca)[1]', 'varchar(50)'), ''))
set	@denumire = rtrim(isnull(@parXML.value('(/row/@denumire)[1]', 'varchar(50)'), ''))
set @update=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)

if @update=1 and isnull(@postlucru,0)<>@o_postlucru and exists (select 1 from devauto where Executant=rtrim(CONVERT(char(3),@o_postlucru)))
begin
		raiserror('Nu este permisa schimbarea codului, deoarece codul vechi este folosit in documente sau in alte cataloage!',11,1)
		return
end
	
if (@update=0 or @update=1 and isnull(@postlucru,0)<>@o_postlucru) and exists (select 1 from Posturi_de_lucru where Postul_de_lucru=@postlucru)
begin
		raiserror('Acest cod exista deja!',11,1)
		return
end
	
if isnull(@postlucru,0)=0 
begin
		raiserror('Cod necompletat!',11,1)
		return
end

if isnull(@denumire,'')=''
begin
		raiserror('Denumire necompletata!',11,1)
		return
end

if not exists (select 1 from lm where cod=isnull(@locmunca,''))
begin
		raiserror('Loc de munca inexistent!',11,1)
		return
end

--Aici incepe partea de modificare
if @update=1
begin
	update Posturi_de_lucru set Postul_de_lucru=@postlucru, Loc_de_munca=@locmunca,
		Consilier_responsabil=@consilier, Denumire=@denumire				
		where Postul_de_lucru=@o_postlucru
	return
end

--Aici incepe partea de adaugare
/*if exists(select Postul_de_lucru from Posturi_de_lucru where Postul_de_lucru=@postlucru)
begin
		declare @err varchar(100)
		set @err = (select 'Postul de lucru '+@postlucru+' exista deja!')
		RAISERROR(@err,16,1)
		return ;

end	
*/
else
	insert into Posturi_de_lucru (Postul_de_lucru, Loc_de_munca, Consilier_responsabil, Denumire)
		VALUES (@postlucru,@locmunca,@consilier,@denumire)
