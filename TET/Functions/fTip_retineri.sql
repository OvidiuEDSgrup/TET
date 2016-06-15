--***
/**	functie tip Retineri	*/
Create function fTip_retineri (@Doar_tipuri int)
returns @tip_retineri table
	(Tip_retinere char(1), Subtip char(4), Denumire_tip char(30), Denumire_subtip char(30))
as
begin
	declare @subtipret int
	Set @Subtipret=dbo.iauParL('PS','SUBTIPRET')

	insert @tip_retineri
	select '1' as tip_retinere, '' as subtip, 'Debite externe' as denumire_tip, '' as denumire_subtip where (@Subtipret=0 or @Doar_tipuri=1)
	union all 
	select '2' as tip_retinere, '' as subtip, 'Rate' as denumire_tip, '' as denumire_subtip where (@Subtipret=0 or @Doar_tipuri=1)
	union all 
	select '3' as tip_retinere, '' as subtip, 'Debite interne' as denumire_tip, '' as denumire_subtip where (@Subtipret=0 or @Doar_tipuri=1)
	union all 
	select '4', '' as subtip, 'CAR cont curent' as denumire_tip, '' as denumire_subtip where (@Subtipret=0 or @Doar_tipuri=1)
	union all 
	select '5', '' as subtip, 'Pensii facultative' as denumire_tip, '' as denumire_subtip where (@Subtipret=0 or @Doar_tipuri=1)
	union all
	select a.tip_retinere as tip_retinere, a.subtip as subtip, b.denumire as denumire_tip, a.denumire as denumire_subtip
	from tipret a
	left outer join 
		(select '1' as tip_retinere, 'Debite externe' as denumire
		union all 
		select '2' as tip_retinere, 'Rate' as denumire 
		union all 
		select '3' as tip_retinere, 'Debite interne' as denumire
		union all 
		select '4', 'CAR cont curent' as denumire
		union all 
		select '5', 'Pensii facultative' as denumire) b on a.tip_retinere=b.tip_retinere
		where @Subtipret=1 and @Doar_tipuri<>1
		
	return 
end
