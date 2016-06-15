--***
/*
Procedura sterge structura arborestenta a unui contract de la pozitia data ca parametru in jos.
In acelasi timp sunt sterse si pozitiile din tabela pozcon relative la nodurile sterse din arborele de structura.
Este apelata din aplicatia DS -> Program de Actualizare contracte furnizori -> task-ul de structura -> Record Suffix pe DELETE MODE
*/
--Declare @tip char(2), @contract char(20), @tert char(13), @data datetime, @pozitie int
--Set @tip = 'FA'
--Set @contract = '1'
--Set @tert = '1'
--Set @data = '2008/01/01'
--Set @pozitie = 1

Create procedure sp_StergNodStruct @tip char(2), @contract char(20), @tert char(13), @data datetime, @pozitie int
as

Declare @cSub char(9), @poz int, @nFetch int
exec luare_date_par 'GE','SUBPRO',1,0,@cSub output
Declare @cr cursor

Set @cr = cursor for select pozitie from structcon where subunitate = @cSub and tip = @tip and contract = @contract and tert = @tert and data = @data and parinte = @pozitie

open @cr
Fetch next from @cr into @poz
Set @nFetch = @@fetch_status
while @nFetch = 0
begin
	exec sp_StergNodStruct @tip,@contract,@tert,@data,@poz
	Fetch next from @cr into @poz
	Set @nFetch = @@fetch_status
end
close @cr
deallocate @cr

Delete from pozcon where subunitate = @cSub and tip = @tip  and contract = @contract and tert = @tert and data = @data and pret_promotional = @pozitie
if @pozitie <> 0 delete from structcon where subunitate = @cSub and tip = @tip  and contract = @contract and tert = @tert and data = @data and pozitie = @pozitie
