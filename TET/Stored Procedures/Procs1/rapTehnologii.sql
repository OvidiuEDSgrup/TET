create procedure rapTehnologii @tehn varchar(20),@tip varchar(20),@catsal char(4),@evid_inloc int,@evid_mat int,@cHostid char(8) output, @tipdoc char(2)=null, @nrdoc char(20)=null, @datadoc datetime=null
As
Begin
declare @HostID char(8),@cod_tehn char(20),@timpinmin int
Set @HostID= (case when isnull(@cHostID,'')='' then (select convert(char(8), abs(convert(int, host_id())))) else @cHostID end)
set @timpinmin=dbo.iauParL('MP','TIMPINMIN')
select @tipdoc=isnull(@tipdoc,''), @nrdoc=isnull(@nrdoc,''), @datadoc=isnull(@datadoc,getdate())

If not exists (Select * from sysobjects where name = 'tschtehn' and type = 'U') 
Begin
Create table dbo.tschtehn (HostID char(8),Cod_tehn char(20),Cant_in_parinte float,Cant_in_produs float,
Nivel float,Ordine float,Cod_parinte char(20),Nr_tehn float,Loc_munca char(9),Nr_fisa char(8),
alfa1 char(20),alfa2 char(20),val1 float,val2 float,cod_produs char(20))
--Create Unique Clustered Index [Marca_locm] ON dbo.tschtehn (HostID Asc,Ordine Asc)
end
delete from dbo.tschtehn where HostID=@HostID

If not exists (Select * from sysobjects where name = 'topprod' and type = 'U') 
Begin
Create table dbo.topprod (HostID char(8),Cod_produs char(20),cod_reper char(20),cod char(20),
Numar_operatie int,Loc_de_munca char(9),Comanda char(13),Timp_de_pregatire float,Timp_util float,
Categoria_salarizare char(4),Norma_de_timp float,Tarif_unitar float,Cantitate_neta float,
Lungime_dupa_op float,Latime_dupa_op float,Inaltime_dupa_op float,cod_produsp char(20))
--Create Unique Clustered Index [Marca_locm] ON dbo.tschtehn (HostID Asc,Ordine Asc)
end
delete from dbo.topprod where HostID=@HostID

If not exists (Select * from sysobjects where name = 'tmatprod' and type = 'U') 
Begin
Create table dbo.tmatprod (HostID char(8),Cod_produs char(20),cod_reper char(20),cod_material char(20),
cod_operatie char(20),tip_material char(1),consum_specific float,cod_inlocuit char(20),Loc_de_munca char(9),Cantitate_neta float,cod_produsp char(20))
end
delete from dbo.tmatprod where HostID=@HostID

Declare cursor_tehnologii Cursor For
select cod_tehn from tehn where @tipdoc='' and (cod_tehn=@tehn or isnull(@tehn,'')='')
union all
select distinct cod from mpdocpoz where tip=@tipdoc and numar=@nrdoc and data=@datadoc
open cursor_tehnologii
fetch next from cursor_tehnologii into @cod_tehn
While @@fetch_status = 0 
Begin
	exec schema_tehn @cod_tehn,1,1,1,1,'',0,'',0,1,@HostID,@cod_tehn
	fetch next from cursor_tehnologii into @cod_tehn
End
close cursor_tehnologii
deallocate cursor_tehnologii

if @tip='Operatii' or @tip='Cumulat'
begin
	insert into topprod(HostID,Cod_produs,cod_reper,cod,Numar_operatie,Loc_de_munca,Comanda,Timp_de_pregatire,Timp_util,
	Categoria_salarizare,Norma_de_timp,Tarif_unitar,Cantitate_neta,Lungime_dupa_op,Latime_dupa_op,Inaltime_dupa_op,cod_produsp)
	select a.HostID,a.cod_produs,a.cod_tehn,max(b.cod),b.nr,max(b.loc_munca),'',0,max(b.timp_util),'',
	sum(b.timp_util*a.Cant_in_produs),sum(a.Cant_in_produs*(case when @timpinmin=1 then d.salar_orar/60*b.timp_util else b.tarif_unitar end)),sum((case when @tip='Cumulat' then a.Cant_in_parinte else a.Cant_in_produs end)),
	0,0,0,a.cod_produs
	from tschtehn a 
	inner join tehnpoz b on b.cod_tehn=a.cod_tehn and b.tip='O'
	left outer join tehnpoz c on c.cod_tehn=b.cod_tehn and c.tip='O' and c.nr=b.nr
	left outer join categs d on d.categoria_salarizare=(case when isnull(@catsal,'')='' then c.categ_salar else @catsal end)
	where a.HostID=@HostID
	group by a.HostID,a.cod_produs,a.cod_tehn,b.nr
end

if @tip='Materiale' or @tip='Cumulat'
begin
	insert into tmatprod(HostID,Cod_produs,cod_reper,cod_material,cod_operatie,tip_material,consum_specific,cod_inlocuit,Loc_de_munca,Cantitate_neta,cod_produsp)
	select a.HostID,a.cod_produs,a.cod_tehn,b.cod,(case when @evid_mat=1 then convert(char(4),b.nr) else b.cod_inlocuit end),
	'',max(b.specific),max(b.cod_inlocuit),b.loc_munca,sum((case when @tip='Cumulat' then a.Cant_in_parinte else a.Cant_in_produs end)),a.cod_produs
	from tschtehn a 
	inner join tehnpoz b on b.cod_tehn=a.cod_tehn and b.tip='M' and ((@evid_inloc=0 and b.cod_inlocuit='') or @evid_inloc=1)
	where a.HostID=@HostID
	group by a.HostID,a.cod_produs,a.cod_tehn,b.cod,(case when @evid_mat=1 then convert(char(4),b.nr) else b.cod_inlocuit end),b.loc_munca
end

set @cHostId=@HostID
end


