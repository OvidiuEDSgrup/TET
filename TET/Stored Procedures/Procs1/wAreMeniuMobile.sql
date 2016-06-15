--***
create procedure wAreMeniuMobile @codMeniu varchar(20),@utilizator varchar(100),@retVal int output
as 
if exists(select * from sysobjects where name='wAreMeniuMobileSP')
	exec wAreMeniuMobileSP @codmeniu=@codmeniu,@utilizator=@utilizator,@retVal=@retVal output
else
	set @retVal=1
return
