--***
create procedure [dbo].[wOPCalculBrutDinNet] @sesiune varchar(50), @parXML xml
as

declare @dataJos datetime, @dataSus datetime, @tipCalcul char(1), @SumaNeta decimal(10), @VenitBrut decimal(10), 
		@asigsanatate float, @casindiv float, @somajindiv float, 
		@NrPersIntr int, @FaraDeducere int, @DedBaza decimal(10), @tipimpozit int, @VenitNet decimal(10), 
		@ProcentSindicat float, @Impozit decimal(10), @Spor decimal(10), @Rotunjire int, 
		@pSalarIncadrare decimal(7), @luna int, @an int, @userASiS varchar(20), @parXMLCalcul xml

begin try  
	exec wIaUtilizator @sesiune, @userASiS OUTPUT

--	citire din XML
	set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
	set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
	if @luna<>0 and @an<>0
	begin
		set @dataJos=convert(datetime,str(@luna,2)+'/01/'+str(@an,4))
		set @dataSus=dbo.EOM(@dataJos)
	end

	set @tipCalcul = ISNULL(@parXML.value('(/parametri/@tipcalcul)[1]', 'char(1)'), 'B')
	set @SumaNeta = ISNULL(@parXML.value('(/parametri/@sumaneta)[1]', 'decimal(10)'), 0)
	set @NrPersIntr = ISNULL(@parXML.value('(/parametri/@nrpersintr)[1]', 'int'), 0)
	set @FaraDeducere = ISNULL(@parXML.value('(/parametri/@faradeducere)[1]', 'int'), 0)
	set @tipimpozit = ISNULL(@parXML.value('(/parametri/@tipimpozit)[1]', 'int'), 1)
	set @ProcentSindicat = ISNULL(@parXML.value('(/parametri/@procsindicat)[1]', 'int'), 0)
	set @Spor = ISNULL(@parXML.value('(/parametri/@spor)[1]', 'decimal(10)'), 0)
	set @VenitBrut=0.0
	set @Rotunjire = 0.0
	set @DedBaza = 0.0
	set @Impozit = 0.0
	set @pSalarIncadrare = 0.0

	--BEGIN TRAN
	if @SumaNeta < 4.0
		raiserror('Suma neta nu poate fi mai mica de 4 lei!' ,16,1)
	if @luna not in (1,2,3,4,5,6,7,8,9,10,11,12)
		raiserror('Alegeti luna de calcul!' ,16,1)
	if @an not in (2010,2011,2012,2013,2014,2015,2016,2017,2018,2019,2020)
		raiserror('Alegeti anul de calcul!' ,16,1)

	exec psInitParLunari @dataJos=@dataJos, @dataSus=@dataSus, @deLaInchidere=0

	declare @mesaj varchar(2000)
--	calcul brut din net	
	if @tipCalcul='B'
	Begin
		exec OPCalculBrutDinNet @dataSus, @SumaNeta, @VenitBrut output, null, null, null, @NrPersIntr, 
			@FaraDeducere, @DedBaza output, @tipimpozit, @ProcentSindicat, @Rotunjire, 
			@Impozit output, @Spor, @pSalarIncadrare output
		
		select @mesaj='Salar de incadrare: '+rtrim(convert(decimal(12,2),isnull(@pSalarIncadrare,0)))+
				' Impozit: '+rtrim(convert(decimal(12,2),isnull(@Impozit,0)))+
				' (Deducere de baza: '+rtrim(convert(decimal(12,2),isnull(@DedBaza,0)))+')'+
				' Venit brut rezultat: '+rtrim(convert(decimal(12,2),isnull(@VenitBrut,0)))
	end
	else 
--	calcul net din brut
	begin
		set @parXMLCalcul=(select @dataSus as datasus, @SumaNeta as venitbrut, @NrPersIntr as nrpersintr, @FaraDeducere as faradeducere, @tipimpozit as tipimpozit,
			@ProcentSindicat as procsindicat for xml raw)
		exec OPCalculNetDinBrut @parXMLCalcul output

		select @venitnet = ISNULL(@parXMLCalcul.value('(/row/@venitnet)[1]', 'decimal(10)'), '0'),
			@casindiv = ISNULL(@parXMLCalcul.value('(/row/@casindiv)[1]', 'decimal(10)'), '0'),
			@asigsanatate = ISNULL(@parXMLCalcul.value('(/row/@asigsanatate)[1]', 'decimal(10)'), '0'),
			@somajindiv = ISNULL(@parXMLCalcul.value('(/row/@somajindiv)[1]', 'decimal(10)'), '0'),
			@impozit = ISNULL(@parXMLCalcul.value('(/row/@impozit)[1]', 'decimal(10)'), '0'),
			@dedBaza = ISNULL(@parXMLCalcul.value('(/row/@dedbaza)[1]', 'decimal(10)'), '0')
		
		select @mesaj=' Venit net rezultat: '+rtrim(convert(decimal(12,2),isnull(@VenitNet,0)))+
				' (CAS individual: '+rtrim(convert(decimal(12,2),isnull(@casindiv,0)))+
				' Asig. sanatate individual: '+rtrim(convert(decimal(12,2),isnull(@asigsanatate,0)))+
				' Somaj individual: '+rtrim(convert(decimal(12,2),isnull(@somajindiv,0)))+
				' Deducere de baza: '+rtrim(convert(decimal(12,2),isnull(@DedBaza,0)))+
				' Impozit: '+rtrim(convert(decimal(12,2),isnull(@Impozit,0)))+')'
				
	 end
	raiserror(@mesaj,16,1)
	--COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
