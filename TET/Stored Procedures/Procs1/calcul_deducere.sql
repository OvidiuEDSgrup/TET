--***
/**	procedura calcul ded. pers	*/
create procedure calcul_deducere
	@venitBrut float, @numarPersIntr int, @deducerePers decimal(12,2) output, 
		@oreJustificate int=0, @oreLuna float=0, @grupaMunca char(1)='N', @regimLucru float=8, 
		@venitBrutCuDed float=null, @venitBrutFaraDed float=null, @DeducereLaOreLucrate int=null
as
begin
	if @venitBrutCuDed is null
		select 
			@venitBrutCuDed=max(case when Parametru='VBCUDEDP' then Val_numerica else 0 end),
			@venitBrutFaraDed=max(case when Parametru='VBFDEDP' then Val_numerica else 0 end),
			@DeducereLaOreLucrate=max(case when Parametru='CHINDPON' then Val_logica else 0 end)
		from par where tip_parametru='PS' and parametru in ('VBCUDEDP','VBFDEDP','CHINDPON')

--	citire deducere personala conform Grilei de deduceri (functie de persoanele in intretinere)
	set @deducerePers = (select top 1 suma_fixa from impozit where tip_impozit='D' and limita <= @numarPersIntr order by limita desc)

--	calcul deducere personala conform formulei de calcul prevazuta in lege (Ordinul nr. 19/07.1.2005)
	if @venitBrut > @venitBrutCuDed and @venitBrut < @venitBrutFaraDed
		Set @deducerePers=@deducerePers * (1 - (@venitBrut - @venitBrutCuDed)/(@venitBrutFaraDed-@venitBrutCuDed))

--	rotunjire deducere personala conform OMF 1016/2005
	if @venitBrut > @venitBrutCuDed and @venitBrut < @venitBrutFaraDed and @deducerePers>0 and cast(ceiling(@deducerePers) as int) % 10<>0
		Set @deducerePers=(round(@deducerePers/10,0,1)+1)*10

--	recalculez deducerea personala functie de orele lucrate (in baza setarii)
--	si apoi o rotunjesc din nou la 10 lei (nu stiu daca o fi corect asa, dar daca prin lege deducerea se rotunjeste in favoarea salariatului, atunci sa fie 2 rotunjiri)
	if @DeducereLaOreLucrate=1 and @oreJustificate<@oreLuna and @oreJustificate<>0
	begin
		set @deducerePers=@deducerePers*@oreJustificate/(@Oreluna*(case when @grupaMunca='C' then @regimLucru/8 else 1 end))
		select @deducerePers=(round(@deducerePers/10,0,1)+1)*10
			where @venitBrut > @venitBrutCuDed and @venitBrut < @venitBrutFaraDed and @deducerePers>0 and cast(ceiling(@deducerePers) as int) % 10<>0
		set @deducerePers=ceiling(@deducerePers)
	end	

	Set @deducerePers=ceiling(@deducerePers)
	if @venitBrut >= @venitBrutFaraDed
		Set @deducerePers=0
end
