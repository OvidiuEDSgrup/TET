--***
/**	functia iau regim de lucru	*/
Create 
function iau_regim_lucru (@marca char(6), @data datetime)
returns float
as
begin
	declare @rl float, @nNr_mediu float, @lReg_var int, @rlPers float, @Grupam char(1)
	Set @lReg_var=dbo.iauParL('PS','REGIMLV')
	Set @nNr_mediu=dbo.iauParLN(@data,'PS','NRMEDOL')
	if @data<>'1901/01/01'
	begin
		set @rlpers=(select isnull(b.salar_lunar_de_baza,a.salar_lunar_de_baza) from personal a
		left outer join istpers b on b.marca=a.marca and b.data=@data where a.marca=@marca)
		set @grupam=(select isnull(b.grupa_de_munca,a.grupa_de_munca) from personal a
		left outer join istpers b on b.marca=a.marca and b.data=@data where a.marca=@marca)
	end
	else
	begin
		set @rlpers=(select isnull(salar_lunar_de_baza,8) from personal where marca=@marca)
		set @grupam=(select isnull(grupa_de_munca,8) from personal where marca=@marca)
	end
	set @rl=(case when @lReg_var=1 then (case when @rlPers=0 then 8 else @rlPers/@nNr_mediu*8 end)
	else (case when @rlPers<>0 then @rlPers else (case when @Grupam in ('N','D','S') then 8 else 3 end) end) end)
return @rl
end
