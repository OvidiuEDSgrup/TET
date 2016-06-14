exec sp_executesql N'/*
declare @PeJurnale bit,@DataJos datetime,@DataSus datetime,@CCont nvarchar(4000),@CuSoldRulaj bit,@EOMDataSus datetime, @locm varchar(20)
select @PeJurnale=0,@DataJos=''2010-11-01 00:00:00'',@DataSus=''2010-11-30 00:00:00'',@CCont=N'''',@CuSoldRulaj=0,@EOMDataSus=''2010-11-30 00:00:00''
--*/
exec rapFisaContului @PeJurnale=@PeJurnale, @DataJos=@DataJos, @DataSus=@DataSus, @CCont=@CCont, @CuSoldRulaj=@CuSoldRulaj, 
	@EOMDataSus=@EOMDataSus, @locm=@locm, @valuta=@valuta, @inValuta=1',N'@PeJurnale bit,@DataJos datetime,@DataSus datetime,@CCont nvarchar(4),@CuSoldRulaj bit,@EOMDataSus datetime,@locm nvarchar(4000),@valuta nvarchar(3)',@PeJurnale=1,@DataJos='2014-06-01 00:00:00',@DataSus='2014-06-30 00:00:00',@CCont=N'401%',@CuSoldRulaj=0,@EOMDataSus='2014-06-30 00:00:00',@locm=NULL,@valuta=N'EUR'