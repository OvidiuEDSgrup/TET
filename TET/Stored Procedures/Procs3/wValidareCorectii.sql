--***
Create 
procedure wValidareCorectii (@sesiune varchar(50), @document xml)
as 
begin
	declare @Subtipcor int, @PrimaV1An int, @tip varchar(2), @dataantet datetime, @data datetime, @tipcor varchar(2), 
	@marca varchar(6), @lm varchar(9), @ptupdate int, @lmsal varchar(9), @Plecat int, @Data_plec datetime, 
	@sumaneta decimal(10), @o_sumacorectie decimal(10), @sumacorectie decimal(10), @mesaj varchar(200)
	set @Subtipcor=dbo.iauParL('PS','SUBTIPCOR')
	set @PrimaV1An=dbo.iauParL('PS','PV-1AN')
	set @tip=isnull(@document.value('(/row/@tip)[1]', 'varchar(2)'), '')
	set @dataantet=isnull(@document.value('(/row/@data)[1]', 'datetime'), '')
	set @data=isnull(@document.value('(/row/row/@data)[1]', 'datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), ''))
	set @tipcor=isnull(@document.value('(/row/@tipcor)[1]', 'varchar(2)'), isnull(@document.value('(/row/row/@tipcor)[1]', 'varchar(2)'), ''))
	set @marca=isnull(@document.value('(/row/@marca)[1]', 'varchar(6)'), isnull(@document.value('(/row/row/@marca)[1]', 'varchar(6)'),''))
	set @lm=isnull(@document.value('(/row/row/@lm)[1]', 'varchar(9)'), '')
	set @ptupdate=isnull(@document.value('(/row/row/@update)[1]', 'int'), 0)
	set @sumaneta=isnull(@document.value('(/row/row/@sumaneta)[1]', 'decimal(10)'), 0)
	set @sumacorectie=isnull(@document.value('(/row/row/@sumacorectie)[1]', 'decimal(10,2)'), 0)
	set @o_sumacorectie=isnull(@document.value('(/row/row/@o_sumacorectie)[1]', 'decimal(10,2)'), 0)
	select @lmsal=loc_de_munca, @Plecat=convert(int,Loc_ramas_vacant), @Data_plec=Data_plec from personal where marca=@marca
	select @lm=@lmsal where @lm='' and @tip<>'CL'

	if @document.exist('/row/row')=1 and @marca not in (select marca from personal) and @tip<>'CL'
	begin
		raiserror('Marca inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @Plecat=1 and @Data_plec<dbo.bom(@data) and @tip<>'CL'
	begin
		set @mesaj='Salariatul selectat este plecat din unitate la '+convert(char(10),@Data_plec,103)+' !'
		raiserror(@mesaj,11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @dataantet<>'01/01/1901' and dbo.eom(@data)<>dbo.eom(@dataantet)
	begin
		raiserror('Data corectiei trebuie sa fie in luna de lucru!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @tipcor = ''
	begin
		set @mesaj=(case when @Subtipcor=0 then 'Tip' else 'Subtip' end)+' corectie venit necompletat!'
		raiserror(@mesaj,11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and (@Subtipcor=0 and @tipcor not in (select tip_corectie_venit from tipcor) or 
	@Subtipcor=1 and @tipcor not in (select subtip from subtipcor))
	begin
		set @mesaj=(case when @Subtipcor=0 then 'Tip' else 'Subtip' end)+' corectie venit incorect!'
		raiserror(@mesaj,11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @PrimaV1An=1 and @ptupdate=0 
	and (@Subtipcor=0 and @tipcor='O-' or @Subtipcor=1 and isnull((select tip_corectie_venit from subtipcor where subtip=@tipcor),'')='O-')
	and isnull((select count(1) from corectii where marca=@marca and data between dbo.boy(@data) and @data and tip_corectie_venit=@tipcor),0)>0
	begin
		select @mesaj='Corectie prima de vacanta acordata pe aceasta marca pe luna: '+rtrim(convert(char(2),month(Data)))+' - '+convert(char(4),year(Data))+' !'
		from corectii where marca=@marca and data between dbo.boy(@data) and @data and tip_corectie_venit=@tipcor
		raiserror(@mesaj,11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and (@lm<>'' or @tip='CL') and @lm not in (select cod from lm)
	begin
		raiserror('Loc de munca inexistent!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @tip in ('CT','SL') and @sumaneta<>0 and @sumacorectie<>@o_sumacorectie 
	begin
		raiserror('Pe corectiile in suma neta nu se pot modifica sumele brute!',11,1)
		return -1
	end
end
