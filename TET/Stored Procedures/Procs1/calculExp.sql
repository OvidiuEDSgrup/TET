--***
CREATE procedure calculExp 
@cCodi char(20),@pDataJ datetime, @pDataS datetime
as

Declare @cHostID char(8)
set @cHostID = convert(char(8),abs(convert(int, host_id())))

if exists (select cod from tmp_calculat where cod = rtrim(@cCodI) and hostid = @cHostID)
	return

declare @cSir char(3000),@Sir char(3000),@cInd char(1000),@cAxe char(1000),@cExpUpd char(3000),@cIndC char(20),@nRel int,@cEl char(50),@cCampuri char(2000)
declare @poz int, @len int, @x int,@nWhere int,@cComSterg char(3000),@axe1 char(3000),@cComUpd nvarchar(3000)
declare @sirS char(3000), @valS float, @val float
declare @boyDJ datetime, @boyDS datetime,@sFiltru char(3000), @campData char(100), @condSQL char(3000),@cWhere char(3000)
declare @nSumaJ float,@nSumaS float,@cCont char(20),@axe char(3000),@nel int,@i int,@j int,@pozi int,@camp char(3000),@cComanda char(3000),@nStru int
declare @nLunaI int,@nAnulI int,@dDataI datetime,@lContin int,@OldPoz int

set @nLunaI=(select val_numerica from par where tip_parametru='GE' and parametru='LUNAIMPL')
set @nAnulI=(select val_numerica from par where tip_parametru='GE' and parametru='ANULIMPL')
set @dDataI=dateadd(month,1,ltrim(str(@nLunaI))+'/01/'+ltrim(str(@nAnulI)))
if @pDataJ<@dDataI set @pDataJ=@dDataI
if @pDataJ>@pDataS return
set @nEl=0 set @Poz=0 set @axe='' set @axe1='' set @cInd='' set @cAxe=''
set @Sir=(select expresia from indicatori where Cod_indicator=@cCodi)

begin
		delete from expval where cod_indicator=@cCodI and ((data between @pDataJ and @pDataS) or data is null) and tip='P'		
		create table #ii(cod_indicator char(20),ComIns char(2000),ComUpd char(2000),Campuri char(2000))
		--delete from colind where cod_indicator=@cCodi
		--delete from compind where parinte=@cCodi
		set @i=1
		set @j=1
		set @cExpUpd=left(@sir,charindex('{',@sir)-1)
		while charindex('[', @sir,@poz)>0 begin
			set @i=charindex('[',@sir,@poz)+1
			set @j=charindex(']',@sir,@poz)
			set @poz=@j+1
			set @camp=substring(@Sir,@i,@j-@i)
			if (select cod_indicator from #ii where cod_indicator=@camp) is null
			begin
				insert into #ii(Cod_indicator) values (@camp)
				--insert into compind (Parinte,Fiu) values (@cCodI,@camp)
				set @axe1=rtrim(@axe1)+'['+rtrim(@camp)+'] float,'
				set @cInd=rtrim(@cInd)+''''+rtrim(@camp)+''''+','
				set @camp=rtrim(@camp)
				if exists(select cod_indicator from indicatori where cod_indicator=@camp)
					exec CalculInd @camp,@pDataJ,@pDataS
				else
					begin --Rulam separat pentru fiecare an in parte deoarece rulajul cumulat se face zero la fiecare inceput de an
						declare @datajosptan datetime,@datasusptan datetime
							select min(data) as dataj,max(data) as datas 
							into #ptCalcule
								from calstd where data between @pdataj and @pDataS
								group by an order by an
						while exists(select 1 from #ptCalcule)
						begin
							select top 1 @datajosptan=dataj,@datasusptan=datas 
								from #ptCalcule order by dataj
							exec CalculCont @camp,@datajosptan,@datasusptan
							delete from #ptCalcule where dataj=@datajosptan and datas=@datasusptan
						end
						drop table #ptCalcule
					end
				end
			end
			declare ii cursor scroll for select Cod_indicator from #ii
			open ii
			set @cInd=left(@cInd,len(rtrim(@cInd))-1)
			set @Poz=@i-1
			set @nEl=0
			while charindex('{', @sir,@poz)>0
			begin
				set @i=charindex('{',@sir,@poz)+1
				set @j=charindex('}',@sir,@poz)
				set @camp=substring(@Sir,@i,@j-@i)
				--insert into colind(Cod_indicator,Numar,Denumire) values (@cCodi,@nEl,left(@camp,30))
				if @nEl=0 begin
					update #ii set ComIns='expval.data,'
					update #ii set ComUpd='tabval.['+rtrim(@camp)+']=expval.data'
					update #ii set Campuri='['+rtrim(@camp)+']'
					set @axe='['+rtrim(@camp)+'] datetime,'
				end
				else 
				begin
					fetch first from ii into @cIndC
					while @@fetch_status=0
					begin
						set @nRel=(select numar from colind where cod_indicator=@cIndC and Denumire=@camp)
						if @nRel is not null and exists (select 1 from indicatori where cod_indicator=@cIndC) 
							or left(@cIndC,2) in ('SI','RL','RC','SC') --Vin din conturi
						begin
							if @nrEl is null --Vine din contur
								set @nrEl=1
							set @cEl='expval.element_'+ltrim(str(@nrEl))
							update #ii set ComIns=rtrim(ComIns)+rtrim(@cEl)+',' where cod_indicator=@cIndC
							update #ii set ComUpd=rtrim(ComUpd)+' and tabval.'+rtrim(@camp)+'='+rtrim(@cEl) where cod_indicator=@cIndC
							update #ii set Campuri=rtrim(Campuri)+',['+rtrim(@camp)+']' where cod_indicator=@cIndC
						end
						else
						begin
							drop table #ii
							close ii
							deallocate ii
							declare @cText char(1000)
							if not exists (select 1 from indicatori where cod_indicator=@cIndC)
								set @cText='Indicatorul '+rtrim(@cIndC)+' nu exista in catalogul de indicatori'
							else
								set @cText='Indicatorul '+rtrim(@cIndC)+' nu are elementul: '+rtrim(@camp)
							RaisError(@cText,16,1)
							return
						end
						fetch next from ii into @cIndC
					end
					set @axe=rtrim(@axe)+'['+rtrim(@camp)+'] char(50),'
				end
			set @cAxe=rtrim(@cAxe)+'['+rtrim(@camp)+'],'
			set @poz=@j+1
			set @nel=@nel+1
	end
	update #ii set ComIns=left(ComIns,len(rtrim(ComIns))-1)
	set @cAxe=left(@cAxe,len(rtrim(@cAxe))-1)
	set @axe=rtrim(@axe)+rtrim(@axe1)+'valoare float'
	set @cComanda='create table tabval(tipcal char(1),'+rtrim(@axe)+')'
	set @cComUpd='create table ##ptins(tipcal char(1),'+rtrim(@axe)+')'
	if exists (Select * from sysobjects where type = 'U' and name = 'tabval') 
		drop table tabval
	exec (@cComanda)
	exec (@cComUpd)
	fetch first from ii into @cIndC
	while @@fetch_status=0
	begin
		set @cComUpd=(select ComIns from #ii where cod_indicator=@cIndC)
		set @cCampuri=(select Campuri from #ii where cod_indicator=@cIndC)
		set @cComanda='insert into ##ptins(tipcal,'+rtrim(@cCampuri)+') select distinct tip,'+rtrim(@cComUpd)+' from expval where data between '''+convert(char(10),@pDataJ,101)+''' and '''+convert(char(10),@pDataS,101)+''' and cod_indicator='+''''+rtrim(@cIndC)+''''
		exec (@cComanda)
		fetch next from ii into @cIndC
	end
	set @cComanda='insert into tabval(tipcal,'+rtrim(@cAxe)+') select distinct tipcal,'+rtrim(@cAxe)+' from ##ptins'
	exec (@cComanda)
	drop table ##ptins
	fetch first from ii into @cIndC
	while @@fetch_status=0
	begin
		set @cComUpd=(select ComUpd from #ii where cod_indicator=@cIndC)
		set @cComanda='update tabval set ['+rtrim(@cIndC)+']=(select sum(expval.valoare) from expval  where expval.tip=tabval.tipcal and expval.cod_indicator='+''''+rtrim(@cIndC)+''''+' and '+rtrim(@cComUpd)+')'
		exec (@cComanda)
		fetch next from ii into @cIndC
	end
	fetch first from ii into @cIndC
	while @@fetch_status=0
	begin
		set @cComanda='update tabval set ['+rtrim(@cIndC)+']=0 where ['+rtrim(@cIndC)+'] is null'
		exec (@cComanda)
		fetch next from ii into @cIndC
	end
	set @cComUpd='update tabval set valoare='+rtrim(@cExpUpd)
	exec (@cComUpd)
	drop table #ii
	close ii deallocate ii
	set @i=@nEl
	while @i<=5
	begin
		set @cAxe=rtrim(@cAxe)+','''''
		set @i=@i+1
	end
	set @cAxe=rtrim(@cAxe)+',valoare'
	set @cComanda='insert into expval select '+''''+rtrim(@cCodI)+''''+',tipcal,'+rtrim(@cAxe)+' from tabval where valoare<>0'
	exec (@cComanda)
	if (@@nestlevel=1) exec dbo.corect_expval
	drop table tabval
end
if not exists(select * from tmp_calculat where hostid=@cHostID and cod=@cCodi)
	insert into tmp_calculat(hostid,cod) values(@cHostID,@cCodi)
