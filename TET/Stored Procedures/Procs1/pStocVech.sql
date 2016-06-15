--***
Create procedure pStocVech @dDataRef datetime, @cTipGest_range char(1), @cGest_range char(9), @cGestlike char(9), 
	@cListGest varchar(300), @cCod_range char(20), @cCont_range varchar(40), @cGrupa_range char(13), @lGrupaStrict bit, 
	@i1 int, @i2 int, @i3 int, @i4 int, @lIstoric bit, @zileDif int, @TipStoc char(1)='', @GRLocM char(1)=''
as

declare @cSub char(9)
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @cSub output

declare @nStoc1 float, @nStoc2 float, @nStoc3 float, @nStoc4 float, @nStoc5 float, 
		@nVal1 float, @nVal2 float, @nVal3 float, @nVal4 float, @nVal5 float, 
		@cTip_gest char(1), @cGest char(9), @cCod char(20), @cDen char(80), @cLm varchar(20), @dData datetime, @nPret float, @nStoc float, 
		@gTip_gest char(1), @gGest char(9), @gCod char(20), @gDen char(80), @gLm varchar(20)

	/**	stocvech = tabela de manevra pe stil vechi pentru retinerea stocurilor pe vechimi*/
Truncate table stocvech

if @cCod_range='' set @cCod_range=null
if @cGest_range='' set @cGest_range=null
	/**	se iau datele din stocuri si se trec printr-un cursor pentru impartirea stocurilor in functie de intervalele cerute: */

	declare @p xml
	select @p=(select @dDataRef dDataSus, @cCod_range cCod, @cGest_range cGestiune, 1 GrCod, 1 GrGest, 1 GrCodi, @TipStoc TipStoc, @cCont_range cCont, @cGrupa_range cGrupa for xml raw)

		if object_id('tempdb..#docstoc') is not null drop table #docstoc
			create table #docstoc(subunitate varchar(9))
			exec pStocuri_tabela
		 
		exec pstoc @sesiune='', @parxml=@p
		
declare cstoc cursor for
select s.tip_gestiune, s.gestiune, s.cod, isnull(n.denumire, ''), isnull(l.cod,'') as loc_de_munca, s.data, 
	(case when s.tip_gestiune='A' then s.pret_cu_amanuntul else s.pret end) as pret, s.stoc
from --dbo.fStocuriCen(@dDataRef, @cCod_range, @cGest_range, null, 1, 1, 1, @TipStoc, @cCont_range, @cGrupa_range, '', '', '', '', '','') s
	#docstoc s
left outer join nomencl n on n.cod = s.cod
left join lm l on s.loc_de_munca=l.Cod and @GRLocM='1'
where s.subunitate = @cSub
and (@dDataRef - s.data) >= isnull(@zileDif, 0)
and (isnull(@cTipGest_range, '') = '' or s.tip_gestiune = @cTipGest_range) 
and (isnull(@cGest_range, '') = '' or s.gestiune = @cGest_range) 
and (isnull(@cCod_range, '') = '' or s.cod = @cCod_range) 
and (isnull(@cCont_range, '') = '' or s.cont like rtrim(@cCont_range)+'%') 
and (isnull(@cGrupa_range, '') = '' or (n.grupa like rtrim(isnull(@cGrupa_range, ''))+'%' and @lGrupaStrict = 0) or (n.grupa = isnull(@cGrupa_range, '') and @lGrupaStrict=1)) 
and (isnull(@cListGest, '') = '' or charindex(','+rtrim(s.gestiune)+',', rtrim(isnull(@cListGest, '')), 0) > 0)
and (isnull(@cGestLike, '') = '' or s.gestiune like rtrim(isnull(@cGestLike, ''))+'%')
order by s.tip_gestiune, s.gestiune, s.cod, isnull(l.cod,'')

open cstoc
fetch next from cstoc into @cTip_gest, @cGest, @cCod, @cDen, @cLm, @dData, @nPret, @nStoc
set @gTip_gest = @cTip_gest
set @gGest = @cGest
set @gCod = @cCod
set @gLm=@cLm
set @gDen = @cDen
set @nStoc1=0 
set @nStoc2=0 
set @nStoc3=0 
set @nStoc4=0 
set @nStoc5=0 
set @nVal1=0 
set @nVal2=0 
set @nVal3=0 
set @nVal4=0 
set @nVal5=0

while @@fetch_status = 0		/**	stocurile se impart pe intervale */
begin
	If @dData >= @dDataRef - @i1 and @dData <= @dDataRef 
	begin
		Set @nStoc1 = @nStoc1 + @nStoc
		Set @nVal1 = @nVal1 + @nStoc * @nPret
	end
	If @dData >= @dDataRef - @i2 and  @dData < @dDataRef - @i1
	begin
		Set @nStoc2 = @nStoc2 + @nStoc
		Set @nVal2 = @nVal2 + @nStoc * @nPret
	end
	If @dData >= @dDataRef - @i3 and  @dData < @dDataRef - @i2
	begin
		Set @nStoc3 = @nStoc3 + @nStoc
		Set @nVal3 = @nVal3 + @nStoc * @nPret
	end
	If @dData >= @dDataRef - @i4 and  @dData < @dDataRef - @i3
	begin
		Set @nStoc4 = @nStoc4 + @nStoc
		Set @nVal4 = @nVal4 + @nStoc * @nPret
	end
	If  @dData < @dDataRef - @i4
	begin
		Set @nStoc5 = @nStoc5 + @nStoc
		Set @nVal5 = @nVal5 + @nStoc * @nPret
	end

	fetch next from cstoc into @cTip_gest, @cGest, @cCod, @cDen, @cLm, @dData, @nPret, @nStoc
	if @cTip_gest <> @gTip_gest or @cGest <> @gGest or @cCod <> @gCod or @cLm<>@gLm or @@fetch_status <> 0
	begin
		if abs(@nStoc1) >= 0.001 or abs(@nStoc2) >= 0.001 or abs(@nStoc3) >= 0.001 or abs(@nStoc4) >= 0.001 or abs(@nStoc5) >= 0.001
			Insert into stocvech
			(Subunitate, Tip_gestiune, Gestiune, Cod, Denumire, Stoc1, Valoare1, Stoc2, Valoare2, Stoc3, Valoare3, Stoc4, Valoare4, Stoc5, Valoare5, Locm)
			Values 
			(@cSub, @gTip_Gest, @gGest, @gCod, left(@gDen, 50), @nStoc1, @nVal1, @nStoc2, @nVal2, @nStoc3, @nVal3, @nStoc4, @nVal4, @nStoc5, @nVal5, @gLm)

		if @@fetch_status = 0
		begin
			set @gTip_gest = @cTip_gest
			set @gGest = @cGest
			set @gCod = @cCod
			set @gLm=@cLm
			set @gDen = @cDen
			set @nStoc1=0
			set @nStoc2=0
			set @nStoc3=0
			set @nStoc4=0
			set @nStoc5=0
			set @nVal1=0
			set @nVal2=0
			set @nVal3=0
			set @nVal4=0
			set @nVal5=0
		end
	end
end

close cstoc
deallocate cstoc
