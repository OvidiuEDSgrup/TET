exec sp_executesql N'/*
declare @PeJurnale bit,@DataJos datetime,@DataSus datetime,@CCont nvarchar(4000),@CuSoldRulaj bit,@EOMDataSus datetime, @locm varchar(20)
select @PeJurnale=0,@DataJos=''2010-11-01 00:00:00'',@DataSus=''2010-11-30 00:00:00'',@CCont=N'''',@CuSoldRulaj=0,@EOMDataSus=''2010-11-30 00:00:00''
--*/
declare @EOMDataSus datetime
set @EOMDataSus=dateadd(D,-day(dateadd(M,1,@DataSus)),dateadd(M,1,@DataSus))

exec rapFisaContului @PeJurnale=@PeJurnale, @DataJos=@DataJos, @DataSus=@DataSus, @CCont=@CCont, @CuSoldRulaj=@CuSoldRulaj, 
	@EOMDataSus=@EOMDataSus, @locm=@locm',N'@PeJurnale bit,@DataJos datetime,@DataSus datetime,@CCont nvarchar(5),@CuSoldRulaj bit,@locm nvarchar(4000)',@PeJurnale=0,@DataJos='2014-06-01 00:00:00',@DataSus='2014-06-30 00:00:00',@CCont=N'401.1',@CuSoldRulaj=0,@locm=NULL