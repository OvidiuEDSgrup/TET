--***
Create function dbo.fAdevRevisalVechime ()
returns @AdevRevisalVechime table
	(crt int, data datetime, marca char(6), Nume char(50), Data_angajarii datetime,
	Nr_contract char(20), Data_contract datetime, DurataContract char(30), Temei char(100),
	Cod_functie char(6), Denumire_functie char(30), Norma float, Salar_de_baza float,
	Data_plecarii datetime, Explicatii varchar(200), DataJ datetime, DataS datetime, Numar_adv char(10))
as
begin
	declare @Data datetime, @Marca char(6), @MarcaAnt char(6), @Nume char(50), @nr_contract as char(20), 
	@Data_contract char(20), @TemeiID char(10), @Data_angajarii datetime, @Mod_angajare char(1), 
	@DurataContract char(30), @DurataContractAnt char(30), @vDurataContract char(30), 
	@cod_functie char(6), @Denumire_functie char(30), @Norma float, @Salar_de_baza as float, 
	@Data_plecarii as datetime, @Data_plecarii_Ant as datetime, @Crt INT, @Explicatii char(50), @ExplicatiiAnt char(50), @vExplicatii char(50), @Temei char(100), 
	@DataJ datetime, @DataS datetime, @DataS_ant datetime, @Angajat int, @Plecat int, @Ang_pl int, @Data_ant datetime,
	@Salar_ant float, @Cod_functie_ant char(30), @Den_functie_ant char(30), @Norma_ant float, 
	@vCod_functie char(6), @vSalar float, @vFunctie char(30), @vNorma float,
	@Datam_salar datetime, @Datam_functie datetime, @Datam_durata datetime, @pMarca char(6), @Data_jos datetime, @Data_sus datetime, 
	@cTerm char(8), @Numar_adv char(10), @Contor int, @DataJ_ant datetime, @PlecatPers int        
	Set @cTerm=isnull((select convert(char(8), abs(convert(int, host_id())))),'')
--	Set @cTerm='2772'
	Set @pMarca=isnull((select Numar from avnefac where AVNEFAC.TERMINAL=@cTerm and tip='AD'),'')
--	Set @Data_jos=dbo.bom(isnull((select Data from avnefac where AVNEFAC.TERMINAL=@cTerm and tip='AD'),'01/01/1901'))
--	citesc data de inceput din avnefac unde se completeaza cu Data de referinta din macheta - asa se vor selecta datele pe o perioada
	Set @Data_jos=dbo.bom(isnull((select Cod_tert from avnefac where AVNEFAC.TERMINAL=@cTerm and tip='AD'),'01/01/1901'))	
	Set @Data_sus=dbo.eom(isnull((select Data from avnefac where AVNEFAC.TERMINAL=@cTerm and tip='AD'),'01/01/1901'))
	Set @Numar_adv=isnull((select Factura from avnefac where AVNEFAC.TERMINAL=@cTerm and tip='AD'),'')

	declare adeverinta_vechime cursor for 
	select c.data, isnull(c.marca,p.marca) as Marca, c.Nume, isnull(c.data_ang, p.data_angajarii_in_unitate) as Data_angajarii, 
	p1.Nr_contract, isnull((select max(data_inf) from extinfop e where e.marca=c.marca and e.cod_inf='DATAINCH'),'01/01/1901'),
	c.Mod_angajare, isnull((select max(val_inf) from extinfop e where e.marca=c.marca and e.cod_inf='TEMEIINCET'),'01/01/1901'),
	isnull(fc.Cod_functie,c.Cod_functie), isnull(fc.Denumire,c.functie), i.Salar_lunar_de_baza as Norma, c.salar, 
--	DateAdd(day,1,isnull(c.data_plec,p.data_plec)) as Data_plecarii, 
	isnull(c.data_plec,p.data_plec) as Data_plecarii, 
	isnull(explicatii,'') as Explicatii, convert(int,p.Loc_ramas_vacant) as PlecatPers   
	from dbo.fRegistru_salariati (@Data_jos, @Data_sus, 0, '', 0, 1, @pMarca, 1, 'T', 0, '', 0, '01/01/1901', 1, 0) c 
		left outer join personal p on c.marca=p.marca
		left outer join infopers p1 on c.marca=p1.marca
		left outer join istpers i on c.data=i.data and c.marca=i.marca
		left outer join extinfop e on e.Marca=c.Cod_functie and e.Cod_inf='#CODCOR'
		left outer join functii_cor fc on fc.Cod_functie=e.Val_inf 
	order by c.data_ang, c.marca, c.data

	open adeverinta_vechime
	fetch next from adeverinta_vechime
	into @Data, @Marca, @Nume, @Data_angajarii, @Nr_contract, @Data_contract, @Mod_angajare, @TemeiID, 
	@Cod_functie, @Denumire_functie, @Norma, @Salar_de_baza, @Data_plecarii, @Explicatii, @PlecatPers
	
	Set @Crt=1
	Set @Contor=1
	while @@fetch_status=0
	begin 
		if @Marca<>@MarcaAnt
			set @Crt=1
		set @DurataContract=(case when @Mod_angajare='D' then 'Determinata' else 'Nedeterminata' end)
		
		Set @Temei=(select Descriere from CatalogRevisal where TipCatalog='TemeiIncetare' and Cod=@TemeiID)
		Set @Angajat=(case when month(@Data_angajarii)=month(@Data_ant) and year(@Data_angajarii)=year(@Data_ant) then 1 else 0 end)
		Set @Plecat=(case when month(@Data_plecarii)=month(@Data) and year(@Data_plecarii)=year(@Data) and @PlecatPers=1 then 1 else 0 end)
		Set @Ang_pl=(case when month(@Data_angajarii)=month(@Data_plecarii) and year(@Data_angajarii)=year(@Data_plecarii) and @PlecatPers=1 then 1 else 0 end)

		Set @Datam_salar=(case when @Salar_de_baza<>@Salar_ant and 
		dbo.eom(isnull((select max(data_inf) from extinfop e where e.marca=@Marca and e.cod_inf='SALAR' and e.procent<>0 and e.Data_inf<=@data),'01/01/1901'))=@Data
		then isnull((select max(data_inf) from extinfop e where e.marca=@Marca and e.cod_inf='SALAR' and e.procent<>0 and e.Data_inf<=@data),'01/01/1901') else '01/01/1901' end)

		Set @Datam_functie=(case when @Cod_functie_ant<>@Cod_functie and 
		dbo.eom(isnull((select max(data_inf) from extinfop e where e.marca=@Marca and e.cod_inf='DATAMFCT' and e.Val_inf<>'' and e.Data_inf<=@data),'01/01/1901'))=@Data
		then isnull((select max(data_inf) from extinfop e where e.marca=@Marca and e.cod_inf='DATAMFCT' and e.Val_inf<>'' and e.Data_inf<=@data),'01/01/1901') else '01/01/1901' end)

		Set @Datam_durata=(case when (@DurataContractAnt<>@DurataContract or @Mod_angajare='D' and @Data_plecarii_Ant<>@Data_plecarii) and 
		dbo.eom(isnull((select max(data_inf) from extinfop e where e.marca=@Marca and e.cod_inf='DATAMDCTR' and e.Val_inf<>'' and e.Data_inf<=@data),'01/01/1901'))=@Data
		then isnull((select max(data_inf) from extinfop e where e.marca=@Marca and e.cod_inf='DATAMDCTR' and e.Val_inf<>'' and e.Data_inf<=@data),'01/01/1901') else '01/01/1901' end)

		Set @DataJ=(case when @Angajat=1 or @Ang_pl=1 or @Contor>1 and @DataJ_ant is null then @Data_angajarii else 
--	Lucian: sesizarea PC053556: daca este vorba de prima pozitie sa se afiseze prima zi 
		(case when @crt=1 then dbo.bom(@DataS_ant) else @DataS_ant+1 end) end)
		      
		Set @DataS=(case when @Plecat=1 and (not(@Salar_de_baza<>@Salar_ant or @Cod_functie_ant<>@Cod_functie) or @Ang_pl=1) then DateADD(day,-1,@Data_plecarii)
			when @Salar_de_baza<>@Salar_ant or @Cod_functie_ant<>@Cod_functie or @DurataContractAnt<>@DurataContract or @Mod_angajare='D' and @Data_plecarii_Ant<>@Data_plecarii
				then (case when @Datam_salar<>'01/01/1901' then DateADD(day,-1,@Datam_salar) when @Datam_functie<>'01/01/1901' then DateADD(day,-1,@Datam_functie)
					when @Datam_durata<>'01/01/1901' then DateADD(day,-1,@Datam_durata) else dbo.eom(dateadd(month,-1,@Data))/*+1*/ end) 
				else @Data end)

		Set @vSalar=(case when @Ang_pl=1 then @Salar_de_baza else isnull(@Salar_ant,@Salar_de_baza) end)
		Set @vCod_functie=(case when @Ang_pl=1 then @Cod_functie else isnull(@Cod_functie_ant,@Cod_functie) end)
		Set @vFunctie=(case when @Ang_pl=1 then @Denumire_functie else isnull(@Den_functie_ant,@Denumire_functie) end)
		Set @vNorma=(case when @Ang_pl=1 then @Norma else isnull(@Norma_ant,@Norma) end)
		Set @vDurataContract=(case when @Ang_pl=1 then @DurataContract else isnull(@DurataContractAnt,@DurataContract) end)
		Set @vExplicatii=(case when @Ang_pl=1 then @Explicatii else isnull(@ExplicatiiAnt,@Explicatii) end)

		if (month(@Data_angajarii)<>month(@Data) or year(@Data_angajarii)<>year(@Data) 
			or month(@Data_angajarii)=month(@Data_plecarii) and year(@Data_angajarii)=year(@Data_plecarii) and @Plecat=1) and @DataJ is not null --and @Explicatii<>''
		Begin
			insert into @AdevRevisalVechime values
			(@Crt, @Data, @Marca, @Nume, @Data_angajarii, @Nr_contract, @Data_contract, @vDurataContract, @Temei, 
			@vCod_functie, @vFunctie, @vNorma, @vSalar, @Data_plecarii, @vExplicatii, @DataJ, @DataS, @Numar_adv)
			Set @Crt=@Crt+1
		End
		Set @Data_ant=@Data
		Set @DataS_ant=@DataS
		Set @Salar_ant=@Salar_de_baza
		Set @Cod_functie_ant=@cod_functie
		Set @Den_functie_ant=@Denumire_functie
		Set @Norma_ant=@Norma
		Set @DurataContractAnt=@DurataContract
		Set @ExplicatiiAnt=@Explicatii
		Set @Data_plecarii_Ant=@Data_plecarii
		Set @MarcaAnt=@Marca
		
		fetch next from adeverinta_vechime
		into @Data, @Marca, @Nume, @Data_angajarii, @Nr_contract, @Data_contract, @Mod_angajare, @TemeiID, 
		@Cod_functie, @Denumire_functie, @Norma, @Salar_de_baza, @Data_plecarii, @Explicatii, @PlecatPers
	End
	if @Plecat=0
	Begin
--		select @salar_de_baza, @Salar_ant
		insert into @AdevRevisalVechime values
		(@Crt, @Data, @Marca, @Nume, @Data_angajarii, @Nr_contract, @Data_contract, @DurataContract, @Temei, 
		@Cod_functie, @Denumire_Functie, @Norma, @Salar_de_baza, @Data_plecarii, @Explicatii, 
		(case when @Crt=1 then @Data_angajarii else @DataS+1 end), convert(datetime,getdate(),103), @Numar_adv)
		set @Crt=@Crt+1        
	End
	return
End

/*
	select * from fAdevRevisalVechime()
*/	
