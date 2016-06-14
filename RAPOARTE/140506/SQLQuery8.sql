exec sp_executesql N'/*
declare @DataJos datetime,@DataSus datetime,@Cont varchar(13),@loc_de_munca varchar(9),@tip int, @desfasurare int, @cusoldrulaj int,
		@centralizare int
	select @DataJos=''2011-1-1'' , @DataSus=''2011-1-31'' , @Cont=''442'' --, @loc_de_munca=''%'' 
			,@tip=0 , @desfasurare=2, @cusoldrulaj=1, @centralizare=1
*/

exec rapFisaContuluiBalanta @DataJos=@DataJos, @DataSus=@DataSus, @Cont=@Cont, @loc_de_munca=@loc_de_munca, @tip=@tip,
	@desfasurare=@desfasurare, @cusoldrulaj=@cusoldrulaj, @centralizare=@centralizare',N'@tip nvarchar(1),@DataJos datetime,@loc_de_munca nvarchar(4000),@Cont nvarchar(3),@DataSus datetime,@desfasurare nvarchar(1),@cusoldrulaj bit,@centralizare nvarchar(1)',@tip=N'0',@DataJos='2013-01-01 00:00:00',@loc_de_munca=NULL,@Cont=N'472',@DataSus='2014-12-30 00:00:00',@desfasurare=N'0',@cusoldrulaj=0,@centralizare=N'1'