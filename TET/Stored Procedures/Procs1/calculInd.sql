--***
CREATE procedure calculInd @cCodi char(20),@pDataJ datetime, @pDataS datetime
as

begin try

delete par where Tip_parametru='TB' and Parametru='LUNA.IND'
insert into par(Tip_parametru, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica)
select 'TB', 'LUNA.IND', 'Luna calcul solduri cu soldtb', 1, 0, convert(datetime,convert(varchar(20),@pDataS,102))

Declare @cHostID char(8)
set @cHostID = convert(char(8),abs(convert(int, host_id())))

if exists (select cod from tmp_calculat where cod = rtrim(@cCodi) and hostid =@cHostID )
	return

if day(@pDataJ)=31 and month(@pDataJ)=12
	set @pDataJ=DATEADD(DAY,1,@pDataJ)


/*Count=2 adica sa am si valoare pentru DataJos si pentru DataSus. */
if not (select count(*) from calstd where data in (@pDataJ,@pDataS))=2
	insert calstd(Data, Data_lunii, An, Luna, LunaAlfa, Zi, Saptamana, Trimestru, Zi_alfa, Camp1, Camp2, Camp3, Fel_zi)
		select f.data, f.data_lunii,f.an,f.luna,f.lunaalfa,f.zi,f.saptamana,f.trimestru,f.zi_alfa,'','','',f.fel_zi 
		from dbo.fCalendar (@pDataJ, @pDataS) f
		left join calstd cs on f.data=cs.data
		where cs.data is null --Doar valorile care nu exista
		

declare @cSir char(3000),@Sir varchar(3000),@cInd char(1000),@cAxe char(1000),@cExpUpd char(3000),@cIndC char(20),@nRel int,@cEl char(50),@cCampuri char(2000)
declare @poz int, @len int, @x int,@nWhere int,@cComSterg char(3000),@axe1 char(3000),@cComUpd nvarchar(3000)
declare @sirS char(3000), @valS float, @val float
declare @boyDJ datetime, @boyDS datetime,@sFiltru char(3000), @campData char(100), @condSQL char(3000),@cWhere char(3000)
declare @nSumaJ float,@nSumaS float,@cCont char(13),@axe char(3000),@nel int,@i int,@j int,@pozi int,@camp char(3000),@cComanda varchar(3000),@nStru int
declare @nLunaI int,@nAnulI int,@dDataI datetime,@lContin int,@OldPoz int

set @nLunaI=(select val_numerica from par where tip_parametru='GE' and parametru='LUNAIMPL')
set @nAnulI=(select val_numerica from par where tip_parametru='GE' and parametru='ANULIMPL')
set @dDataI=dateadd(month,1,ltrim(str(@nLunaI))+'/01/'+ltrim(str(@nAnulI)))
if @pDataJ<@dDataI set @pDataJ=@dDataI
if @pDataJ>@pDataS return
set @nEl=0 set @Poz=0 set @axe='' set @axe1='' set @cInd='' set @cAxe=''
set @Sir=(select expresia from indicatori where Cod_indicator=@cCodi)

delete from expval where cod_indicator=@cCodI and ((data between @pDataJ and @pDataS) or data is null) and tip='E'
if left(@sir,4)='EXEC' -- calcul cu proceduri stocate
BEGIN
	set @cComanda =@sir+', @dataj='''+CONVERT(CHAR(10),@pDataJ,102)+''',@datas='''+CONVERT(CHAR(10),@pDataS,102)+''''
	EXEC (@cComanda)
END
else -- calcul fara proceduri stocate:
if (charindex('[',@sir,0) > 0 and charindex(']',@sir,0) > 0) -- calcul din expresii de indicatori
	exec CalculExp @cCodi,@pDataJ,@pDataS
else -- calcul din select-uri
begin
	set @nStru=(select modificat from indicatori where Cod_indicator=@cCodi)
	set @nStru=0--Nu umblam niciodata la structura
	
	
	set @axe=''
	set @nel=0
	set @poz=charindex('EXPANDEZ', @sir)
	set @pozi=@poz-1
	if @poz>0 begin
		set @cComSterg='delete from expval where cod_indicator='+''''+rtrim(@cCodI)+''''+' and ((data is null) and tip=''E'''
		if @nStru=1 delete from colind where cod_indicator=@cCodi
		while charindex('{', @sir,@poz)>0 begin
			set @i=charindex('{',@sir,@poz)+1
			set @j=charindex('}',@sir,@poz)
			set @camp=substring(@Sir,@i,@j-@i)
			if @nStru=1 begin
				insert into colind(Cod_indicator,Numar,Denumire) values (@cCodi,@nEl,substring(@camp,charindex('.',@camp)+1,30))
				update indicatori set modificat=0 where cod_indicator=@cCodi
			end
			set @axe=rtrim(@axe)+','+@camp
			if @nEl=0 begin
				set @oldpoz=0
				set @nWhere=charindex('from', @sir,@oldpoz)
				set @lContin=1
				while @lContin=1 begin
					set @oldpoz=@nWhere
					set @nWhere=charindex('from', @sir,@oldpoz+1)
					if @nWhere=0 set @lContin=0
				end
				set @nWhere=charindex('where', @sir,@oldpoz+1)
				if @camp<>'DATAAZI' begin
					if @nWhere>0 begin	
						set @condSQL=substring(@sir,@nWhere,@Poz-@nWhere)
						set @condSQL = ' and'
					end
					else begin
						set @condSQL=' where '
					end
					set @condSQL = rtrim(@condSQL) + ' ' + rtrim(@camp) + ' between ''' + rtrim(convert(char, @pDataJ, 101)) + ''' and ''' + rtrim(convert(char, @pDataS, 101)) + ''''
				end
				else begin
					delete from expval where cod_indicator=@cCodI and tip='E'
					set @condSQL=''
				end
			end
			else begin
				set @cComSterg=rtrim(@cComSterg)+' or (element_'+ltrim(str(@nEl))+' is null)'
			end
			set @poz=@j+1
			set @nel=@nel+1
		end
		set @cComSterg=rtrim(@cComSterg)+')'
		set @axe=substring(@axe,2,500)
		set @camp=@axe
		set @axe=REPLACE(@axe,'DATAAZI,','')
		set @camp=REPLACE(@camp,'DATAAZI','convert(datetime,convert(char(10),getdate(),101),101)')
		while @nEl<=5
		begin
			set @camp=rtrim(@camp)+','''''
			set @nEl=@nel+1
		end
		set @i=charindex(' ',@sir)+1
		set @cComanda='select '+''''+rtrim(@cCodI)+''''+','+'''E'''+','+rtrim(@camp)+','++substring(@sir,@i,@pozi-@i)
		set @cComanda=rtrim(@cComanda)+rtrim(@condSQL)+' group by '+rtrim(@axe)--+' with cube'
		set @cComanda = 'insert into expval '+rtrim(@cComanda)
		--select @cComanda
		exec (@cComanda)
		if (@@nestlevel=1) exec dbo.corect_expval 
		if 0=0 or (select Total from indicatori where cod_indicator=@cCodI)=0
			exec (@cComSterg)
		set @sir=@sirs
	end
end

if not exists(select * from tmp_calculat where hostid=@cHostID and cod=@cCodi)
	insert into tmp_calculat(hostid,cod) values(@cHostID,@cCodi)

end try
begin catch
	declare @eroare varchar(1000)
	set @eroare='calculInd (linia '+ convert(varchar(20),ERROR_LINE())+'):'+char(10)+
				rtrim(ERROR_MESSAGE())
	raiserror(@eroare,16,1)
end catch
