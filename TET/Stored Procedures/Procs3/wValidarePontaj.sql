--***
Create 
procedure wValidarePontaj (@sesiune varchar(50), @document xml)
as 
begin
	declare @sub varchar(9), @validcomstrictGE int, @SalariatiPeComenzi int, 
	@ptupdate int, @subtip varchar(2), @data datetime, @marca varchar(6), @lm varchar(9), @nrcrt int, @comanda varchar(20),
	@lmantet varchar(9), @lmsal varchar(9),	@tipsal char(1), @tipsalpers char(1), @Plecat int, @Data_plec datetime, 
	@oreacord int, @orerealizate decimal(12,2), @realizat decimal(12,2), @mesaj varchar(200)

	select	@sub = (case when Tip_parametru='GE' and parametru='SUBPRO' then Val_alfanumerica else @sub end), 
			@validcomstrictGE = (case when Tip_parametru='GE' and parametru='COMANDA' then Val_numerica else @validcomstrictGE end),
			@SalariatiPeComenzi = (case when Tip_parametru='PS' and parametru='SALCOM' then Val_logica else @SalariatiPeComenzi end)
	from par
	where (Tip_parametru='GE' and (Parametru='SUBPRO' or Parametru='COMANDA')) 
		or (Tip_parametru='PS' and (Parametru='SALCOM' or Parametru='PONTZILN' or Parametru='REGIMLV'))

	set @ptupdate=isnull(@document.value('(/row/row/@update)[1]','int'),0)
	set @subtip=isnull(@document.value('(/row/row/@subtip)[1]','varchar(2)'),'')
	Set @data=isnull(@document.value('(/row/row/@data)[1]', 'datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), ''))
	set @marca=isnull(@document.value('(/row/row/@marca)[1]', 'varchar(6)'), isnull(@document.value('(/row/@marca)[1]', 'varchar(6)'), ''))
	set @lm=isnull(@document.value('(/row/row/@lm)[1]', 'varchar(9)'), '')
	set @nrcrt=@document.value('(/row/row/@nrcrt)[1]', 'int')
	set @comanda=isnull(@document.value('(/row/row/@comanda)[1]', 'varchar(20)'), '')
	set @lmantet=isnull(@document.value('(/row/@lmantet)[1]','varchar(9)'),'')
	set @tipsal=@document.value('(/row/row/@tipsal)[1]','varchar(1)')
	set @oreacord=isnull(@document.value('(/row/row/@oreacord)[1]','int'),0)
	set @orerealizate=isnull(@document.value('(/row/row/@orerealizate)[1]','decimal(12,2)'),0)
	set @realizat=isnull(@document.value('(/row/row/@realizat)[1]','decimal(12,2)'),0)

	select @lmsal=loc_de_munca, @tipsalpers=Tip_salarizare, @Plecat=convert(int,Loc_ramas_vacant), @Data_plec=Data_plec
	from personal where marca=@marca
	select @lm=@lmsal where @lm=''

	if @comanda='' and @SalariatiPeComenzi=1 and (@ptupdate=0 or @validcomstrictGE=1)
		select @comanda=centru_de_cost_exceptie from infopers where marca=@marca

	if @document.exist('/row/row')=1 and not exists (select marca from personal where Marca=@marca)
	begin
		raiserror('Eroare operare (wValidarePontaj): Marca inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @Plecat=1 and @Data_plec<dbo.bom(@data)
	begin
		set @mesaj='Eroare operare (wValidarePontaj): Salariatul selectat este plecat din unitate la '+convert(char(10),@Data_plec,103)+' !'
		raiserror(@mesaj,11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and not exists (select cod from lm where Cod=@lm)
	begin
		raiserror('Eroare operare (wValidarePontaj): Loc de munca inexistent!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @lmsal<>@lmantet and left(@subtip,1) in ('P','S') and @lmantet<>''
	begin
		raiserror('Eroare operare (wValidarePontaj): Salariatul apartine de alt loc de munca decat locul de munca selectat!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @comanda='' and @validcomstrictGE=1 and @SalariatiPeComenzi=1
	begin
		raiserror('Eroare operare (wValidarePontaj): Comanda necompletata!!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @comanda<>'' and not exists (select comanda from comenzi where Subunitate=@sub and Comanda=@comanda)
	begin
		raiserror('Eroare operare (wValidarePontaj): Comanda inexistenta!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @oreacord<>0 and isnull(@tipsal,@tipsalpers) in ('1','3','6')
	begin
		raiserror('Eroare operare (wValidarePontaj): Nu se completeaza ore acord pt. tip salarizare regie!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @orerealizate<>0 and isnull(@tipsal,@tipsalpers) in ('1','3','6')
	begin
		raiserror('Eroare operare (wValidarePontaj): Nu se completeaza ore realizate pt. tip salarizare regie!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and @realizat<>0 and isnull(@tipsal,@tipsalpers) in ('1','3','6')
	begin
		raiserror('Eroare operare (wValidarePontaj): Nu se completeaza suma realizata acord pt. tip salarizare regie!',11,1)
		return -1
	end

/*
	if isnull((select sum(ore_regie+ore_acord+ore_concediu_medical+ore_concediu_de_odihna+ore_nemotivate+ore_concediu_fara_salar+ore_invoiri) from pontaj where data between @datalunii1 and @datalunii and marca=@marca),0)>@ore_luna
	set @eroare_atentie='<error coderoare="1" msgeroare="'+'Numarul de ore justificate depaseste numarul de ore lucratoare'+'"/>'
*/	
end
