--***
/**	functie numar mediu ang bass	*/
Create function fUnificareTipStatPlata ()
Returns varchar(8000)
As
Begin
	declare @tipStatPlata varchar(8000)
	select @tipStatPlata=''
	select @tipStatPlata=@tipStatPlata+rtrim(Tip_stat_plata)+','
	from TipStatPlata
	if right(rtrim(@tipStatPlata),1)=','	
		select @tipStatPlata=reverse(substring(reverse(rtrim(@tipStatPlata)),2,8000))

	Return (@tipStatPlata)
End
