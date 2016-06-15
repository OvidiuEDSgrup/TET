--***
create procedure wTipFormularAS2000 @sesiune varchar(50), @parXML xml                 
as

set nocount on 

/*
--Pentru formulare care nu au deloc completat campul OBIECT nu functioneaza bine
--Se poate rula o singura data acest cod

update formular set obiect='R'+replicate('0',2-len(ltrim(str(rand))))+ltrim(str(rand))+'C'
	+replicate('0',2-len(ltrim(str(pozitie))))+ltrim(str(pozitie)) from formular
where formular='FPV4' and obiect=''
*/

begin try

	declare @nrform varchar(13), @chostId varchar(100), @debug bit

	select	@nrform =  @parXML.value('(/row/@nrform)[1]','varchar(13)'),
			@debug = isnull(@parXML.value('(/row/@debug)[1]','bit'),0), -- daca e 1, afisez selectul rulat pt. date
			@chostId =  @parXML.value('(/row/@hostid)[1]','varchar(13)')

	--set @nrform='RTXT'


	delete from tmpFormularAS2000 where utilizator=@chostId

	declare @rand int,@coloana int,@nivel int,@expresie varchar(max),@cPtRez nvarchar(max),@raspunsTMP varchar(max),@totalpozitii int
	declare @obiect varchar(20),@tip int,@pozitie int,@linie varchar(max),@nF int,@numarrand int,@randuridepe2 int,@ultimuldepe2 varchar(max)

	select @randuridepe2=-1*count(*) from formular where formular=@nrform and tip=2
	select @randuridepe2=@randuridepe2+1

	select top 1 @ultimuldepe2=obiect from formular where formular=@nrform and tip=2 order by rand desc,pozitie desc
	set @cPtRez='select @totalpozitii=count(*) from ##rasp'+@cHostID
	exec sp_executesql @statement=@cPtRez, @params=N'@totalpozitii int out', @totalpozitii=@totalpozitii output

	declare tmpForm scroll cursor for
	select obiect,tip,rand,pozitie from formular where formular=@nrform and expresie not like '%apelproc%' order by tip,rand,pozitie
	open tmpForm

	fetch next from tmpForm into @obiect,@tip,@rand,@pozitie
	set @nF=@@FETCH_STATUS

	declare @rCurent int
	set @rCurent=0
	set @numarrand=1 --variabila ce se va plimba prin ##rasp doar la tipul 2
	while @nF=0
	begin
		
		set @linie=REPLICATE(' ',300)
		if @rCurent>@rand+@numarrand-1
		begin
			set @rCurent=@rand+@numarrand-1
			select @linie=linie from tmpFormularAS2000 where utilizator= @chostId and rand=@rCurent
		end
		
		while @rCurent<@rand+@numarrand-1
		begin
			set @rCurent=@rCurent+1
			if not exists (select 1 from tmpFormularAS2000 where utilizator= @chostId and rand=@rCurent)
				insert into tmpFormularAS2000 values(@chostId,@rCurent,@linie)
		end

		set @cPtRez='set @raspunsTMP=isnull((select ['+@obiect+'] as [text()] from ##rasp'+@cHostID+' where numarrand=@numarrand),'''')'
		exec sp_executesql @statement=@cPtRez, @params=N'@numarrand int,@raspunsTMP nvarchar(max) out', @raspunsTMP=@raspunsTMP output, @numarrand=@numarrand


		if LEN(@raspunsTMP)>0
			update tmpFormularAS2000 set linie=isnull(stuff(linie,@pozitie,len(@raspunsTMP),@raspunsTMP),linie) where utilizator=@chostId and RAND=@rCurent

		if @numarrand=@totalpozitii and @obiect=@ultimuldepe2
		begin
			set @ultimuldepe2='' --pentru a nu mai intra in pozitii vreodata
			set @numarrand=1 --pentru a nu decala footerul
		end

		if @obiect='RESETF'
		begin
			declare @ultimaLinieScrisa int
			select @ultimaLinieScrisa=max(rand) from tmpFormularAS2000 where utilizator=@chostId and rand<@rCurent and linie!=''
			delete from tmpFormularAS2000 where utilizator=@chostId and linie='' and rand>@ultimaLinieScrisa
		end

		if @obiect=@ultimuldepe2 and @numarrand<@totalpozitii
		begin
			set @numarrand=@numarrand+1
			fetch relative @randuridepe2 from tmpForm
				into @obiect,@tip,@rand,@pozitie
		end
		else
		begin
			fetch next from tmpForm into @obiect,@tip,@rand,@pozitie
		end
		
		set @nF=@@FETCH_STATUS

	end

	close tmpForm
	deallocate tmpForm

	set @cPtRez='insert into ##form'+@cHostID +char(13)+
		'select rtrim(linie) from tmpformularas2000 where utilizator=@chostId order by rand'
		
	exec sp_executesql @statement=@cPtRez, @params=N'@chostId as varchar(max)', @chostId = @chostId
	
	if @debug=1
		select * from tmpFormularAS2000 where utilizator=@chostId
end try
begin catch
	declare @ErrorMessage varchar(8000)
	SELECT @ErrorMessage = ERROR_MESSAGE()+ ' (wTipFormularAS2000)'

	raiserror(@ErrorMessage,11,1)
end catch
