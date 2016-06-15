--***
/**	functie pt. calcul zile concediu medical (incapacitate temporara de munca pt. inceput) efectuate in ultimele 12 luni */
Create function fCalculZileCMefectuate
	(@Marca char(6), @DataJos datetime, @DataSus datetime, @Data_inceput datetime, @Tip_diagnostic char(30))
Returns int
As
Begin
	Declare @zileCMefectuate int

	select @zileCMefectuate=isnull((select sum(DateDIFF(day,cm.Data_inceput,cm.Data_sfarsit)+1)
		from conmed cm
			left outer join infoconmed icm on icm.Data=cm.Data and icm.Marca=cm.Marca and icm.Data_inceput=cm.Data_inceput
		where cm.data between @DataJos and @DataSus and cm.marca=@Marca 
			and (@tip_diagnostic<>'1-5-6-13' or icm.Nr_aviz_me='')
			and (@Data_inceput in ('01/01/1901','') or cm.Data_inceput<@Data_inceput) 
			and (@Tip_diagnostic='' or charindex(tip_diagnostic,@tip_diagnostic)<>0)),0) 

	Return round(@zileCMefectuate,0)
End
