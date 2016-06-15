--***
create procedure [dbo].[schema_tehn](@reper varchar(20),@cant_reper_parinte float,@cant_reper_sel float,
@nivel int,@ordine int,@cod_parinte varchar(20),@nr_reper float,@locm varchar(9),@compl_fisa bit,@fara_sterg bit,@HostID char(8),@cod_produs varchar(20))
as
begin
declare @NrFisa int,@tcod_parinte char(20),@cNrFisa varchar(20),@SpIbegapam bit,@lSchmatsf bit
if @fara_sterg=0
	delete from dbo.tschtehn where HostID=@HostID
if @compl_fisa=1
begin
	Set @NrFisa=dbo.iauParN('MP','NRFISAREP')
	if @NrFisa>99999999
		set @NrFisa=1
	else
		set @NrFisa=@NrFisa+1
	exec setare_par 'MP','NRFISAREP',null,null,@NrFisa,null
end
else
begin
	set @NrFisa=0
end
set @SpIbegapam=dbo.iauParL('SP','BEGAPAM')
set @lSchmatsf=dbo.iauParL('MP','SCHMATSF')

set @cNrFisa=convert(varchar(8),@NrFisa)
set @tcod_parinte=(case when @cod_parinte='' then @reper else @cod_parinte end)
insert into dbo.tschtehn
select @HostID,@reper,@cant_reper_parinte,@cant_reper_sel,@nivel,@ordine,@tcod_parinte,
@nr_reper,@locm,@cNrFisa,'','',0,0,@cod_produs

--Declare cursor_reper Cursor For
Declare @cursor_reper Cursor
set @cursor_reper=Cursor for
select a.cod_tehn as cod_reper_parinte,a.cod as cod_reper,a.specific as cant_reper_parinte,
a.nr as nr_reper,a.loc_munca as locm,b.Cant_in_produs,b.nivel,c.specific as consum_specific
from
(select cod_tehn, cod, specific, nr, loc_munca from tehnpoz where tip='S' and @SpIbegapam=0 and cod_tehn=@reper
union all
select a.cod_tehn, a.cod, 0, nr, a.loc_munca from tehnpoz a left outer join nomencl b on a.cod=b.cod where @SpIbegapam=1 and a.tip='M' and a.cod_tehn=@reper and b.tip='P'
union all
select a.cod_tehn, a.cod, a.specific, nr, a.loc_munca from tehnpoz a where @lSchmatsf=1 and a.tip='M' and a.cod_tehn=@reper and a.subtip='E') a
left outer join tschtehn b on b.HostID=@HostID and b.cod_tehn=a.cod_tehn
left outer join tehnpoz c on c.cod_tehn=a.cod_tehn and c.tip='M' and c.cod=a.cod
where @cod_parinte='' or b.cod_parinte=@cod_parinte
declare @cant1 float,@cant2 float,@tnivel int,@tordine int
declare @tcod_reper_parinte varchar(20),@tcod_reper varchar(20),@tcant_reper_parinte float,
@tnr_reper float,@tlocm varchar(9),@tCant_in_produs float,@tconsum_specific float


open @cursor_reper
fetch next from @cursor_reper into @tcod_reper_parinte,@tcod_reper,@tcant_reper_parinte,
@tnr_reper,@tlocm,@tCant_in_produs,@tnivel,@tconsum_specific

While @@fetch_status = 0 
Begin
	set @cant1=(case when @SpIbegapam=1 then @tconsum_specific else @tcant_reper_parinte end)
	set @cant2=@cant1*@tCant_in_produs
	set @tnivel=@tnivel+1
	set @tordine=@ordine+1
	exec schema_tehn @tcod_reper,@cant1,@cant2,@tnivel,@tordine,@tcod_reper_parinte,
		@tnr_reper,@tlocm,@compl_fisa,1,@HostID,@cod_produs
	fetch next from @cursor_reper into @tcod_reper_parinte,@tcod_reper,@tcant_reper_parinte,
	@tnr_reper,@tlocm,@tCant_in_produs,@tnivel,@tconsum_specific
End
close @cursor_reper
Deallocate @cursor_reper
end
