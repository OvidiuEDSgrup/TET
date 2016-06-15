--***
/*	functie pentru calcul varsta exprimata in aniu, luni, zile 
	am ales aceasta varianta in locul celei prin diferenta intre 2 date (extragere ani, luni, zile din data obtinuta din @data_sfarsit-@data_inceput) intrucat aceasta este exacta
	varianta cu diferenta intre 2 date poate avea diferente de 1-2-3 zile */
Create
function fCalculVarsta (@Data_inceput datetime, @Data_sfarsit datetime)
Returns char(25)
As
Begin
	Declare @varsta_ani int, @varsta_luni int, @varsta_zile int, @DataPtAni datetime, @DataPtLuni datetime
--	stabilesc varsta in ani
	set @varsta_ani=DATEDIFF(year,@Data_inceput,@Data_sfarsit)
	set @DataPtAni=DATEADD(year,@varsta_ani,@Data_inceput)
	set @varsta_ani=@varsta_ani+(case when @DataPtAni>@Data_sfarsit then -1 else 0 end)
	set @DataPtAni=DATEADD(year,@varsta_ani,@Data_inceput)

--	stabilesc varsta in luni
	set @varsta_luni=DATEDIFF(MONTH,@DataPtAni,@Data_sfarsit)
	set @DataPtLuni=DATEADD(month,@varsta_luni,@DataPtAni)
	set @varsta_luni=@varsta_luni+(case when @DataPtLuni>@Data_sfarsit then -1 else 0 end)
	set @DataPtLuni=DATEADD(month,@varsta_luni,@DataPtAni)

--	stabilesc varsta in zile
	set @varsta_zile=DATEDIFF(DAY,@DataPtLuni,@Data_sfarsit)

	Return rtrim(convert(char(3),@varsta_ani))+' ani '+convert(char(2),@varsta_luni)+' luni '+convert(char(2),@varsta_zile)+' zile'
End
